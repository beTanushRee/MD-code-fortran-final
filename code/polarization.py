import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import binned_statistic_2d
import os
import subprocess
import csv

start_file = 1000
end_file = 1200
lsize = 46.0  
grid_boxes = 10  

dir_arrows = 'plots_polarization_arrows'
dir_pure = 'plots_polarization_colours'
os.makedirs(dir_arrows, exist_ok=True)
os.makedirs(dir_pure, exist_ok=True)

time_steps = []
avg_box_polarizations = []
csv_filename = 'grid_calculations.csv'

with open(csv_filename, mode='w', newline='') as csv_file:
    writer = csv.writer(csv_file)
    writer.writerow(['Frame', 'Box_X_Center', 'Box_Y_Center', 'Particle_Count', 'Local_Polarization', 'Local_Theta'])

    print(f"Processing and generatingvisualizations {start_file} to {end_file}...")
    
    for fnum in range(start_file, end_file + 1):
        filename = f'fort.{fnum}'
        if not os.path.exists(filename):
            continue
            
        data = np.loadtxt(filename)
        x, y, ex, ey = data[:, 0], data[:, 1], data[:, 2], data[:, 3]
        
        ex_sum, xedges, yedges, _ = binned_statistic_2d(
            x, y, ex, statistic='sum', bins=grid_boxes, range=[[0, lsize], [0, lsize]]
        )
        ey_sum, _, _, _ = binned_statistic_2d(
            x, y, ey, statistic='sum', bins=grid_boxes, range=[[0, lsize], [0, lsize]]
        )
        counts, _, _, _ = binned_statistic_2d(
            x, y, ex, statistic='count', bins=grid_boxes, range=[[0, lsize], [0, lsize]]
        )
        
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
        
        # Write to folder
        for i in range(grid_boxes):
            for j in range(grid_boxes):
                count = int(counts[i, j])
                if count > 0:
                    writer.writerow([
                        fnum, round(X_grid[i, j], 3), round(Y_grid[i, j], 3), 
                        count, round(local_polarization[i, j], 6), round(local_theta[i, j], 6)
                    ])

        # Visualization plots
        fig1, ax1 = plt.subplots(figsize=(6.5, 5.5))
        im1 = ax1.imshow(local_polarization.T, extent=(0, lsize, 0, lsize), origin='lower', 
                         cmap='inferno', interpolation='bicubic', vmin=0, vmax=1)
        
        for x_line in xedges:
            ax1.axvline(x_line, color='black', linewidth=0.8, alpha=0.15)
        for y_line in yedges:
            ax1.axhline(y_line, color='black', linewidth=0.8, alpha=0.15)

        cbar1 = fig1.colorbar(im1, ax=ax1, fraction=0.046, pad=0.04)
        cbar1.set_label('Local Polarization $P$', rotation=270, labelpad=15, fontsize=10)
        cbar1.ax.tick_params(labelsize=9)

        for i in range(grid_boxes):
            for j in range(grid_boxes):
                count = int(counts[i, j])
                if count > 0:
                    u = np.cos(local_theta[i, j])
                    v = np.sin(local_theta[i, j])
                    ax1.quiver(X_grid[i, j], Y_grid[i, j], u, v, color='white', pivot='mid', 
                               scale=grid_boxes*3.5, width=0.0025, headwidth=3.0, headlength=3.5)
                    
                    offset_x = (lsize / grid_boxes) * 0.45
                    offset_y = (lsize / grid_boxes) * 0.45
                    ax1.text(X_grid[i, j] + offset_x, Y_grid[i, j] - offset_y, str(count), 
                             color='white', fontsize=6, alpha=0.85, ha='right', va='bottom')
        
        ax1.set_xlim(0, lsize); ax1.set_ylim(0, lsize)
        ax1.set_xticks([]); ax1.set_yticks([])
        ax1.set_title(f"Frame: {fnum}", fontsize=12, pad=10)
        fig1.tight_layout()
        fig1.savefig(f'{dir_arrows}/frame_{fnum:05d}.png', dpi=200) 
        plt.close(fig1)

        fig2, ax2 = plt.subplots(figsize=(6.5, 5.5))
        im2 = ax2.imshow(local_polarization.T, extent=(0, lsize, 0, lsize), origin='lower', 
                         cmap='inferno', interpolation='bicubic', vmin=0, vmax=1)
        
        for x_line in xedges:
            ax2.axvline(x_line, color='black', linewidth=0.8, alpha=0.15)
        for y_line in yedges:
            ax2.axhline(y_line, color='black', linewidth=0.8, alpha=0.15)

        cbar2 = fig2.colorbar(im2, ax=ax2, fraction=0.046, pad=0.04)
        cbar2.set_label('Local Polarization $P$', rotation=270, labelpad=15, fontsize=10)
        cbar2.ax.tick_params(labelsize=9)
        
        ax2.set_xlim(0, lsize); ax2.set_ylim(0, lsize)
        ax2.set_xticks([]); ax2.set_yticks([])
        ax2.set_title(f"Frame: {fnum}", fontsize=12, pad=10)
        fig2.tight_layout()
        fig2.savefig(f'{dir_pure}/frame_{fnum:05d}.png', dpi=200) 
        plt.close(fig2)

# GLOBAL AVERAGE LINE GRAPH 
fig, ax = plt.subplots(figsize=(6, 4))
ax.plot(time_steps, avg_box_polarizations, color='black', linewidth=1.5)
ax.set_xlabel('Time Step', fontsize=10)
ax.set_ylabel(r'$\langle P_{local} \rangle$', fontsize=11)
ax.set_title('Global Average of Local Polarization', fontsize=11)
ax.grid(True, linestyle=':', alpha=0.6)
ax.tick_params(labelsize=9)
plt.tight_layout()
plt.savefig('analysis_avg_box_polarization.png', dpi=300)
plt.close(fig)

# gifs
print("Calculations complete. Stitching GIFs...")

try:
    subprocess.run([
        "ffmpeg", "-y", "-framerate", "6", 
        "-pattern_type", "glob", "-i", f"{dir_arrows}/frame_*.png", 
        "-vf", "split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse",
        "-loop", "0", "polarization_flow_arrows.gif"
    ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
    
    subprocess.run([
        "ffmpeg", "-y", "-framerate", "6", 
        "-pattern_type", "glob", "-i", f"{dir_pure}/frame_*.png", 
        "-vf", "split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse",
        "-loop", "0", "polarization_flow_pure.gif"
    ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
    
    print("Success!")
except Exception as e:
    print("Error generating GIFs:", e)
