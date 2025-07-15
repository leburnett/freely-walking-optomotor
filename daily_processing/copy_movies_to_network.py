import os
import shutil

def sync_videos_and_log_missing(local_root, network_root, log_path):
    missing_videos_folders = []
    total_copied = 0
    total_skipped_folders = 0

    for date_folder in os.listdir(local_root):
        local_date_path = os.path.join(local_root, date_folder)
        if not os.path.isdir(local_date_path):
            continue

        for root, dirs, files in os.walk(local_date_path):
            relative_path = os.path.relpath(root, local_root)
            print(f"Checking: {relative_path}")

            mp4_files = [f for f in files if f.lower().endswith(".mp4")]
            if not mp4_files:
                print(f"No videos found in {relative_path}")
                missing_videos_folders.append(relative_path)
                continue

            network_folder = os.path.join(network_root, relative_path)
            all_exist = all(os.path.exists(os.path.join(network_folder, f)) for f in mp4_files)
            if all_exist:
                print(f"All videos already present in {relative_path}, skipping.")
                total_skipped_folders += 1
                continue

            os.makedirs(network_folder, exist_ok=True)
            for mp4 in mp4_files:
                local_mp4 = os.path.join(root, mp4)
                network_mp4 = os.path.join(network_folder, mp4)
                if not os.path.exists(network_mp4):
                    print(f"Copying {mp4} to {relative_path}")
                    shutil.copy2(local_mp4, network_mp4)
                    total_copied += 1

    with open(log_path, 'w') as log_file:
        for folder in missing_videos_folders:
            log_file.write(f"{folder}\n")

    print(f"\nSummary:")
    print(f"Copied {total_copied} videos.")
    print(f"Skipped {total_skipped_folders} folders (all videos present).")
    print(f"{len(missing_videos_folders)} folders logged with no videos.")

if __name__ == "__main__":
    local_root = r"C:\Users\burnettl\Documents\oakey-cokey\DATA\02_processed"
    network_root = r"\\prfs\reiserlab\oaky-cokey\data\2_processed"
    log_file_path = r"C:\Users\burnettl\Documents\oakey-cokey\logs\missing_videos_log.txt"

    os.makedirs(os.path.dirname(log_file_path), exist_ok=True)
    sync_videos_and_log_missing(local_root, network_root, log_file_path)
