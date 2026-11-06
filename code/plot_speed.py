import numpy as np
import matplotlib.pyplot as plt
import os
import subprocess

output_dir = 'plots_velocity'
os.makedirs(output_dir, exist_ok=True)
lsize = 46.0

# 1. Load the pre-calculated data from Fortran
data = np.loadtxt('grid_velocity.dat', skiprows=1)
frames = np.unique(data[:, 0])

print("Drawing flowing heatmaps from Fortran data...")

for fnum in frames:
    # Get only the data for this specific frame
    frame_data = data[data[:, 0] == fnum]
    
    # Create an empty 10x10 grid
    grid = np.zeros((10, 10))
    
    # Fill the grid with the Fortran averages
    for row in frame_data:
        ix = int(row[1]) - 1  # Subtract 1 because Python arrays start at 0
        iy = int(row[2]) - 1
        avg_v = row[3]
        grid[iy, ix] = avg_v  # iy is row, ix is column
        
    # 2. Draw the plot
    fig, ax = plt.subplots(figsize=(6.5, 5.5))
    
    # Flowing colors using bicubic interpolation
    im = ax.imshow(grid, origin='lower', extent=(0, lsize, 0, lsize),
                   cmap='inferno', interpolation='bicubic', vmin=0, vmax=2.5)
    
    # Faint division lines
    for i in range(1, 10):
        ax.axvline(i * (lsize/10), color='black', linewidth=0.8, alpha=0.15)
        ax.axhline(i * (lsize/10), color='black', linewidth=0.8, alpha=0.15)

    cbar = fig.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
    cbar.set_label(r'Local Average Speed $\langle V \rangle$', rotation=270, labelpad=15, fontsize=10)
    
    ax.set_xticks([]); ax.set_yticks([])
    ax.set_title(f"Frame: {int(fnum)}", fontsize=12, pad=10)
    
    plt.tight_layout()
    plt.savefig(f'{output_dir}/frame_{int(fnum):05d}.png', dpi=200)
    plt.close(fig)

# 3. Stitch into GIF
print("Stitching GIF...")
subprocess.run([
    "ffmpeg", "-y", "-framerate", "6", "-pattern_type", "glob", 
    "-i", f"{output_dir}/frame_*.png", 
    "-vf", "split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse", 
    "-loop", "0", "velocity_flow.gif"
], stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
print("Done! Check velocity_flow.gif")
