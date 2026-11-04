import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import binned_statistic_2d
import os
import subprocess
import csv

# --- Parameters ---
start_file = 1000
end_file = 1200
lsize = 46.0  
grid_boxes = 8  

output_dir = 'plots_boxes'
os.makedirs(output_dir, exist_ok=True)

time_steps = []
avg_box_polarizations = []

csv_filename = 'grid_calculations.csv'
with open(csv_filename, mode='w', newline='') as csv_file:
    writer = csv.writer(csv_file)
    writer.writerow(['Frame', 'Box_X_Center', 'Box_Y_Center', 'Particle_Count', 'Local_Polarization', 'Local_Theta'])

    print(f"Processing and plotting frames {start_file} to {end_file}... Please wait.")
    
    for fnum in range(start_file, end_file + 1):
        filename = f'fort.{fnum}'
        if not os.path.exists(filename):
            continue
            
        data = np.loadtxt(filename)
        x, y, ex, ey = data[:, 0], data[:, 1], data[:, 2], data[:, 3]
        
        # Divide space into boxes & sum components
        ex_sum, xedges, yedges, _ = binned_statistic_2d(x, y, ex, statistic='sum', bins=grid_boxes, range=[[0, lsize], [0, lsize]])
        ey_sum, _, _, _ = binned_statistic_2d(x, y, ey, statistic='sum', bins=grid_boxes, range=[[0, lsize], [0, lsize]])
        counts, _, _, _ = binned_statistic_2d(x, y, ex, statistic='count', bins=grid_boxes, range=[[0, lsize], [0, lsize]])
        
        x_centers = (xedges[:-1] + xedges[1:]) / 2
        y_centers = (yedges[:-1] + yedges[1:]) / 2
        X_grid, Y_grid = np.meshgrid(x_centers, y_centers, indexing='ij')

        local_polarization = np.zeros_like(counts)
        local_theta = np.zeros_like(counts)
        valid = counts > 0  
        
        local_polarization[valid] = np.sqrt(ex_sum[valid]**2 + ey_sum[valid]**2) / counts[valid]
        local_theta[valid] = np.arctan2(ey_sum[valid], ex_sum[valid])
        
        frame_avg_polarization = np.mean(local_polarization[valid]) if np.any(valid) else 0.0
        time_steps.append(fnum - start_file)
        avg_box_polarizations.append(frame_avg_polarization)
        
        plt.figure(figsize=(8, 7))
        
        # bicubic interpolation
        plt.imshow(local_polarization.T, extent=(0, lsize, 0, lsize), origin='lower', 
                   cmap='viridis', interpolation='bicubic', vmin=0, vmax=1, alpha=0.85)
        plt.colorbar(label='Local Polarization (0 to 1)')
        
        for x_line in xedges:
            plt.axvline(x_line, color='white', linewidth=0.3, alpha=0.2)
        for y_line in yedges:
            plt.axhline(y_line, color='white', linewidth=0.3, alpha=0.2)

        # Plot arrows and record the exact particle count inside each box
        for i in range(grid_boxes):
            for j in range(grid_boxes):
                count = int(counts[i, j])
                if count > 0:
                    # Write to CSV
                    writer.writerow([fnum, round(X_grid[i, j], 3), round(Y_grid[i, j], 3), 
                        count, round(local_polarization[i, j], 6), round(local_theta[i, j], 6)])
                    
                    u = np.cos(local_theta[i, j])
                    v = np.sin(local_theta[i, j])
                    plt.quiver(X_grid[i, j], Y_grid[i, j], u, v, color='white', pivot='mid', scale=grid_boxes*1.8)
                    
                    # Overlay Particle Count Text
                    offset = lsize / (grid_boxes * 2.5)
                    plt.text(X_grid[i, j] + offset, Y_grid[i, j] - offset, str(count), 
                             color='white', fontsize=9, alpha=0.8, ha='center', va='center', fontweight='bold')
        
        plt.xlim(0, lsize); plt.ylim(0, lsize)
        plt.xticks([]); plt.yticks([])
        plt.title(f"Flowing Polarization & Particle Counts - Frame {fnum}")
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/frame_{fnum:05d}.png', dpi=150)
        plt.close()

print("\nGenerating global average polarization plot...")
plt.figure(figsize=(8, 4))
plt.plot(time_steps, avg_box_polarizations, color='purple', linewidth=2.5)
plt.xlabel('Time Step')
plt.ylabel('Average of Local Box Polarizations')
plt.title('Global Average of Local Coarse-Grained Polarization vs Time')
plt.grid(True, linestyle='--', alpha=0.7)
plt.tight_layout()
plt.savefig(f'{output_dir}/analysis_avg_box_polarization.png', dpi=200)
plt.close()

print(f"Numbers saved to {csv_filename}. Stitching frames into a slow animated GIF...")
gif_name = "polarization_flow.gif"

ffmpeg_cmd = ["ffmpeg", "-y", "-framerate", "6", "-pattern_type", "glob", "-i", f"{output_dir}/frame_*.png", 
    "-vf", "split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse","-loop", "0", gif_name]

try:
    subprocess.run(ffmpeg_cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
    print("Success!")
except Exception as e:
    print("Error generating GIF:", e)
