"""
Download Gemma 3 1B model from Hugging Face Hub.
Handles authentication via environment variable or interactive input.
"""

import os
import sys
from pathlib import Path
from getpass import getpass
import click
from huggingface_hub import snapshot_download, login
from huggingface_hub.utils import HfHubHTTPError


def get_hf_token():
    """Get Hugging Face token from environment or interactive input."""
    token = os.getenv("HF_TOKEN")
    
    if token:
        print("✓ Found HF_TOKEN in environment variables")
        return token
    
    print("HF_TOKEN not found in environment variables.")
    print("Please enter your Hugging Face token (get it from https://huggingface.co/settings/tokens):")
    token = getpass("HF Token: ").strip()
    
    if not token:
        print("❌ No token provided. Exiting.")
        sys.exit(1)
    
    return token


def download_gemma_model(model_name):
    """Download specified model to .artifacts directory."""
    # Model configuration
    artifacts_dir = Path(__file__).parent.parent / ".artifacts"
    model_dir = artifacts_dir / model_name
    
    # Create artifacts directory
    artifacts_dir.mkdir(exist_ok=True)
    
    print(f"📁 Artifacts directory: {artifacts_dir.absolute()}")
    print(f"🎯 Model: {model_name}")
    print(f"📂 Download location: {model_dir.absolute()}")
    
    # Get and validate token
    token = get_hf_token()
    
    try:
        # Login to Hugging Face
        print("🔐 Authenticating with Hugging Face...")
        login(token=token)
        print("✓ Authentication successful")
        
        # Download model
        print(f"⬇️  Downloading {model_name}...")
        print("This may take several minutes depending on your internet connection...")
        
        snapshot_download(
            repo_id=model_name,
            local_dir=str(model_dir),
            token=token,
            resume_download=True,
            local_dir_use_symlinks=False
        )
        
        print(f"✅ Model downloaded successfully to: {model_dir.absolute()}")
        print(f"📊 Model size: {get_directory_size(model_dir):.2f} GB")
        
    except HfHubHTTPError as e:
        if e.response.status_code == 401:
            print("❌ Authentication failed. Please check your token.")
        elif e.response.status_code == 403:
            print("❌ Access denied. You may need to accept the model license on Hugging Face.")
            print(f"   Visit: https://huggingface.co/{model_name}")
        else:
            print(f"❌ HTTP Error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Download failed: {e}")
        sys.exit(1)


def get_directory_size(path):
    """Calculate directory size in GB."""
    total_size = 0
    for dirpath, dirnames, filenames in os.walk(path):
        for filename in filenames:
            filepath = os.path.join(dirpath, filename)
            if os.path.exists(filepath):
                total_size += os.path.getsize(filepath)
    return total_size / (1024**3)  # Convert to GB


@click.command()
@click.option(
    "--model",
    "-m",
    default="google/gemma-3-1b-it",
    help="Hugging Face model name to download",
    show_default=True
)
def main(model):
    """Download models from Hugging Face Hub."""
    print("🤖 Gemma Model Downloader")
    print("=" * 40)
    download_gemma_model(model)


if __name__ == "__main__":
    main()
