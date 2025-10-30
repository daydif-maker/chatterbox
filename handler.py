import base64
import io
import runpod
import torchaudio as ta

from chatterbox.tts import ChatterboxTTS
from chatterbox.mtl_tts import ChatterboxMultilingualTTS

# Load once at cold start
EN_MODEL = ChatterboxTTS.from_pretrained(device="cuda")
MTL_MODEL = ChatterboxMultilingualTTS.from_pretrained(device="cuda")

def synth_to_wav_bytes(wav_tensor, sr):
    buf = io.BytesIO()
    ta.save(buf, wav_tensor.cpu(), sr, format="wav")
    return buf.getvalue()

def handler(event):
    """
    Expected input:
    {
      "input": {
        "text": "Hello world",
        "language_id": "en",        # optional, triggers multilingual
        "audio_prompt_url": null,   # optional cloning ref (wav/mp3)
        "cfg_weight": 0.5,          # optional
        "exaggeration": 0.5         # optional
      }
    }
    """
    payload = event.get("input", {})
    text = payload.get("text", "")
    language_id = payload.get("language_id")
    cfg_weight = float(payload.get("cfg_weight", 0.5))
    exaggeration = float(payload.get("exaggeration", 0.5))
    audio_prompt_path = None  # (Optional) download if provided

    if not text:
        return {"error": "Missing 'text'."}

    if language_id:
        wav = MTL_MODEL.generate(
            text,
            language_id=language_id,
            audio_prompt_path=audio_prompt_path,
            cfg_weight=cfg_weight,
            exaggeration=exaggeration
        )
        sr = MTL_MODEL.sr
    else:
        wav = EN_MODEL.generate(
            text,
            audio_prompt_path=audio_prompt_path,
            cfg_weight=cfg_weight,
            exaggeration=exaggeration
        )
        sr = EN_MODEL.sr

    wav_b = synth_to_wav_bytes(wav, sr)
    b64 = base64.b64encode(wav_b).decode("utf-8")
    return {"audio_wav_base64": b64, "sample_rate": sr}

if __name__ == "__main__":
    print(handler({"input": {"text": "Hello from Chatterbox", "language_id": "en"}}))

runpod.serverless.start({"handler": handler})
