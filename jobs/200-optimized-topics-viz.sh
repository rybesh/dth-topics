#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH --mem 200G
#SBATCH -n 16
#SBATCH -t 8:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ryanshaw@email.unc.edu

module add make/4.3
module add python/3.8.3
module add java/10.0.2
module add apache-ant/1.10.8
module add go/1.14.4

cd "$HOME/dth-topics" || exit
MEMORY=200g \
CPUS=16 \
SCRATCH="$HOME/scratch" \
make viz/200-optimized-topics/index.html
