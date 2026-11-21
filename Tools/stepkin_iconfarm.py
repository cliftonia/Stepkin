#!/usr/bin/env python3
"""Generate Stepkin app-icon concepts via a local ComfyUI (SDXL + pixel-art-xl).

Runs ON the server (talks to 127.0.0.1:8188). Stdlib only (urllib). Saves PNGs
to ComfyUI/output/ with a per-concept prefix (stepkin_<label>_...).
"""
import json
import time
import urllib.request
import uuid

COMFY = "http://127.0.0.1:8188"
CKPT = "sd_xl_base_1.0.safetensors"
LORA = "pixel-art-xl.safetensors"
ROUNDS = 2          # queues per concept
BATCH = 2           # images per queue  -> ROUNDS*BATCH per concept

COMMON_POS = (
    "pixel art, app icon, single centered subject, simple bold shapes, "
    "clean, high contrast, vibrant, cute mascot, flat colours, full background"
)
NEG = (
    "text, words, letters, watermark, signature, ui, blurry, jpeg artifacts, "
    "realistic, photograph, 3d render, multiple subjects, frame, border, "
    "rounded corners, low contrast, cluttered background, sad, scary"
)

CONCEPTS = [
    ("skypet", "a cute round fluffy creature mascot with big friendly eyes, "
               "soft pastel blue sky with a bright sun and one small cloud, kawaii"),
    ("dragon", "an adorable tiny baby dragon pet with big sparkly eyes, "
               "dusk gradient sky pink and purple with a few stars, cozy and friendly"),
    ("blob",   "a happy little slime blob creature with a big grin and tiny feet, "
               "clean solid teal background, minimal, bold, chunky pixels"),
    ("egg",    "a cute speckled monster egg with a happy little face, glowing, "
               "deep blue night sky with stars behind it, centered, friendly"),
    ("skybird", "a tiny round pixel chick with little wings, big eyes, "
                "bright daytime sky with soft clouds, adorable, bold"),
    ("starpet", "a cute star-shaped cloud creature with a smiling face, "
                "twilight sky gradient with sparkles, soft glow, friendly mascot"),
]


def build_workflow(pos, seed, prefix, batch=BATCH):
    return {
        "4": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "10": {"class_type": "LoraLoader",
               "inputs": {"lora_name": LORA, "strength_model": 1.0,
                          "strength_clip": 1.0, "model": ["4", 0], "clip": ["4", 1]}},
        "6": {"class_type": "CLIPTextEncode", "inputs": {"text": pos, "clip": ["10", 1]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["10", 1]}},
        "5": {"class_type": "EmptyLatentImage",
              "inputs": {"width": 1024, "height": 1024, "batch_size": batch}},
        "3": {"class_type": "KSampler",
              "inputs": {"seed": seed, "steps": 30, "cfg": 7.0,
                         "sampler_name": "dpmpp_2m_sde", "scheduler": "karras",
                         "denoise": 1.0, "model": ["10", 0],
                         "positive": ["6", 0], "negative": ["7", 0], "latent_image": ["5", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["4", 2]}},
        "9": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["8", 0]}},
    }


def queue(workflow):
    body = json.dumps({"prompt": workflow, "client_id": str(uuid.uuid4())}).encode()
    req = urllib.request.Request(COMFY + "/prompt", data=body,
                                 headers={"Content-Type": "application/json"})
    return json.loads(urllib.request.urlopen(req, timeout=30).read())["prompt_id"]


def wait(prompt_id, timeout=300):
    start = time.time()
    while time.time() - start < timeout:
        with urllib.request.urlopen(COMFY + f"/history/{prompt_id}", timeout=30) as r:
            hist = json.loads(r.read())
        if prompt_id in hist:
            outs = hist[prompt_id].get("outputs", {})
            return [i["filename"] for n in outs.values() for i in n.get("images", [])]
        time.sleep(2)
    return []


def main():
    base = int(time.time())
    for idx, (label, subject) in enumerate(CONCEPTS):
        pos = f"{COMMON_POS}, {subject}"
        for r in range(ROUNDS):
            seed = base + idx * 1000 + r * 137
            pid = queue(build_workflow(pos, seed, f"stepkin_{label}"))
            files = wait(pid)
            print(f"[{label} r{r}] {files}", flush=True)
    try:
        urllib.request.urlopen(urllib.request.Request(
            COMFY + "/free",
            data=json.dumps({"unload_models": True, "free_memory": True}).encode(),
            headers={"Content-Type": "application/json"}), timeout=30)
        print("freed VRAM", flush=True)
    except Exception as exc:  # noqa: BLE001
        print(f"free failed: {exc}", flush=True)


if __name__ == "__main__":
    main()
