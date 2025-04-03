import os
import sys
from concurrent.futures import ThreadPoolExecutor
try:
    import yt_dlp
except ImportError:
    print("Error: yt-dlp not installed. Run setup.ps1 or 'pip install yt-dlp'.")
    sys.exit(1)

# Set the download directory
download_path = r"D:\GNO-PY\videos"
os.makedirs(download_path, exist_ok=True)

def download_link(url, format_choice):
    """Download a single URL as MP4 (video+audio) or MP3 (audio-only)."""
    if format_choice.lower() in ['v', 'video']:
        ydl_opts = {
            'format': 'bestvideo+bestaudio/best',
            'merge_output_format': 'mp4',
            'outtmpl': os.path.join(download_path, '%(title)s.%(ext)s'),
        }
    elif format_choice.lower() in ['a', 'audio']:
        ydl_opts = {
            'format': 'bestaudio',
            'postprocessors': [{
                'key': 'FFmpegExtractAudio',
                'preferredcodec': 'mp3',
                'preferredquality': '320',
            }],
            'outtmpl': os.path.join(download_path, '%(title)s.%(ext)s'),
        }
    else:
        print(f"Invalid choice for {url}. Skipping.")
        return

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])
        print(f"Completed: {url} -> {download_path}")
    except Exception as e:
        print(f"Error downloading {url}: {e}")

def main():
    # Prompt for single or multiple links
    num_links = input("Enter number of YouTube links (1 or more): ").strip()
    if not num_links.isdigit() or int(num_links) < 1:
        print("Invalid input. Exiting.")
        sys.exit(1)
    num_links = int(num_links)

    links = []
    for i in range(num_links):
        link = input(f"Enter YouTube URL #{i+1}: ").strip()
        links.append(link)

    if num_links == 1:
        # Single link: ask format each time
        url = links[0]
        while True:
            choice = input(f"Download {url} as (V)ideo MP4 or (A)udio MP3? (V/A, or Q to quit): ").strip().lower()
            if choice == 'q':
                break
            if choice in ['v', 'a']:
                download_link(url, choice)
                break
            print("Invalid choice. Enter 'V' or 'A'.")
    else:
        # Multiple links: ask for batch or custom
        batch_choice = input("Download all as (V)ideo MP4, (A)udio MP3, or (C)ustom per link? (V/A/C): ").strip().lower()
        if batch_choice in ['v', 'a']:
            # Concurrent downloads for all video or all audio
            with ThreadPoolExecutor() as executor:
                executor.map(lambda url: download_link(url, batch_choice), links)
        elif batch_choice == 'c':
            # Custom: list links and get choices
            print("\nLinks to download:")
            for i, url in enumerate(links, 1):
                print(f"{i}. {url}")
            choices = []
            for i, url in enumerate(links, 1):
                while True:
                    choice = input(f"#{i} {url} - (V)ideo MP4 or (A)udio MP3? (V/A): ").strip().lower()
                    if choice in ['v', 'a']:
                        choices.append((url, choice))
                        break
                    print("Invalid choice. Enter 'V' or 'A'.")
            # Concurrent downloads for custom choices
            with ThreadPoolExecutor() as executor:
                executor.map(lambda x: download_link(x[0], x[1]), choices)
        else:
            print("Invalid choice. Exiting.")
            sys.exit(1)

if __name__ == "__main__":
    main()
