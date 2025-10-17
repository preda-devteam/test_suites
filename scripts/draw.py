import re
import matplotlib.pyplot as plt
import numpy as np
import os
import random
import argparse
def extract_data_from_log(filename):
    with open(filename, 'r') as file:
        log_content = file.read()

    parallel_tps_match = re.search(r'parallel execution tps:\s*\[([^\]]+)\]', log_content)
    speed_up_match = re.search(r'speed up:\s*\[([^\]]+)\]', log_content)

    if not parallel_tps_match or not speed_up_match:
        raise ValueError("The required data was not found in the log file")

    parallel_tps = list(map(int, parallel_tps_match.group(1).split(',')))
    speed_up = list(map(float, speed_up_match.group(1).split(',')))
    n = min(len(parallel_tps), len(speed_up),7)
    return parallel_tps[:n], speed_up[:n]

def plot_parallel_tps(parallel_tps_group,labels,title):
    # plt.rcParams['font.family'] = 'Times New Roman'
    # plt.rcParams['font.size'] = 10
    width = 0.16
    fig, ax = plt.subplots()
    x = np.arange(len(labels))
    group_sz = len(list(parallel_tps_group))
    next_pos = x - (group_sz - 1) * 0.5 * width
    if "Sei" in parallel_tps_group:
        rects5 = ax.bar(next_pos, parallel_tps_group["Sei"], width, label='Sei', color='grey')
        ax.bar_label(rects5, fontsize=5.5, padding=1)
        next_pos += width
    if "Aptos" in parallel_tps_group:
        rects1 = ax.bar(next_pos, parallel_tps_group["Aptos"], width, label='Aptos', color='royalblue')
        ax.bar_label(rects1, fontsize=5.5, padding=1)
        next_pos+=width
    if "Sui" in parallel_tps_group:
        rects2 = ax.bar(next_pos, parallel_tps_group["Sui"], width, label='Sui', color='green')
        ax.bar_label(rects2, fontsize=5.5, padding=1)
        next_pos += width
    if "Crystality" in parallel_tps_group:
        rects3 = ax.bar(next_pos, parallel_tps_group["Crystality"], width, label='Crystality', color='orangered')
        ax.bar_label(rects3, fontsize=5.5, padding=1)
        next_pos += width
    if "Preda" in parallel_tps_group:
        rects4 = ax.bar(next_pos, parallel_tps_group["Preda"], width, label='Preda', color='darkviolet')
        ax.bar_label(rects4, fontsize=5.5, padding=1)
        next_pos += width
    

    ax.grid(True, which='both', linestyle='--', linewidth=0.5, alpha=0.3)

    ax.set_xlabel('Num. of Parallel VMs')
    ax.set_ylabel('Throughput (Transactions per Second)')
    ax.set_title('{} Transactions '.format(title))
    ax.set_xticks(x)
    ax.set_xticklabels(labels)
    ax.legend()
    fig.tight_layout()
    plt.savefig('../pictures/{}_tps.pdf'.format(title), format='pdf')
    # plt.show()

def plot_speed_up(speed_up_groups,labels,title):
    # plt.rcParams['font.family'] = 'Times New Roman'
    # plt.rcParams['font.size'] = 10
    fig, ax = plt.subplots()
    x = np.arange(len(labels))  # the label locations
    width = 0.15  # the width of the bars
    if "Sei" in speed_up_groups:
        rects5 = ax.plot(x, speed_up_groups["Sei"], label='Sei', marker='+',linewidth=3.5,markersize=7,color='grey')
    if "Aptos" in speed_up_groups:
        rects1 = ax.plot(x, speed_up_groups["Aptos"], label='Aptos', marker='X',linewidth=3.5,markersize=7,color='royalblue')
    if "Sui" in speed_up_groups:
        rects2 = ax.plot(x, speed_up_groups["Sui"], label='Sui', marker='v',linewidth=3.5,markersize=7,color='green')
    if "Crystality" in speed_up_groups:
        rects3 = ax.plot(x, speed_up_groups["Crystality"], label='Crystality', marker='s',linewidth=3.5,markersize=7,color='orangered')
    if "Preda" in speed_up_groups:
        rects4 = ax.plot(x, speed_up_groups["Preda"], label='Preda', marker='D',linewidth=3.5,markersize=7,color='darkviolet')
    

    # Add grid
    ax.grid(True, which='both', linestyle='--', linewidth=0.5)

    ax.set_xlabel('Number of Parallel VMs')
    ax.set_ylabel('Relative Speedup')
    ax.set_title('{} Transactions '.format(title))

    ax.set_xticks(x)
    ax.set_xticklabels(labels)
    ax.legend(loc="best")
    fig.tight_layout()
    plt.savefig('../pictures/{}_speed_up.pdf'.format(title), format='pdf')
    # plt.show()
def iterate_files_in_directory(directory,parallel_tps_group,speed_up_groups,label):
    pattern = re.compile(r'{}_(\w+)\.log'.format(label))
    for root, dirs, files in os.walk(directory):
        for file in files:
            match = pattern.match(file)
            file_path = os.path.join(root, file)
            if match:
                key = match.group(1)
                parallel_tps_group[key], speed_up_groups[key]= extract_data_from_log(file_path)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('action', type=str)
    args = parser.parse_args()
    base_path = '../results'
    full_path = f"{base_path}/{args.action}/"
    parallel_tps_group = {}
    speed_up_group = {}
    iterate_files_in_directory(full_path,parallel_tps_group,speed_up_group,args.action)
    if len(list(parallel_tps_group)) == 0:
        print("No corresponding folders and files in {}.".format(full_path))
        exit(0)
    random_key = random.choice(list(parallel_tps_group.keys()))
    random_value = parallel_tps_group[random_key]
    try:
        plot_parallel_tps(parallel_tps_group,[2**i for i in range(len(random_value))],args.action)
        plot_speed_up(speed_up_group,[2**i for i in range(len(random_value))],args.action)
    except Exception as e:
        print(f"An error occurred: {e}")
    print("case run finished, output in test-suite/pictures/.")