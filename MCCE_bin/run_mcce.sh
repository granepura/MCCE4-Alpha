#!/bin/bash

# Check if a file is provided
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <file.pdb> [-dry] [-l 2] [-d N] [-s ngpb|zap] [-h]"
    exit 1
fi

for arg in "$@"; do
    if [ "$arg" == "-h" ]; then
        echo "Usage: $0 <file.pdb> [-dry] [-l 2] [-d N] [-s ngpb|zap]"
        echo "Options:"
        echo "  -h            Show this help message."
	    echo "  -l [2|3]      Level of conformer creation (level 1 is default)."
        echo "  -d            Dielectric constant; 4 and 8 are standard choices."
	    echo "  -s [ngpb|zap] Poisson-Boltzmann Equation solver. NGPB is default."
	    echo "  -dry          Ignore waters in the protein file."
        # Add more options as needed
        exit 0
    fi
done

# Extract the file argument
PDB_FILE="$1"
shift

# Check if the file has a .pdb extension
if [[ "$PDB_FILE" != *.pdb ]]; then
    echo "Error: File must have a .pdb extension."
    exit 1
fi

# Initialize flags
DRY_FLAG=""
L_FLAG=""
D_FLAG=""
S_FLAG=""
SALT_FLAG=""

# Parse additional flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        -dry)
            DRY_FLAG="--dry"
            ;;
        -l)
            if [[ "$2" == "2" ]]; then
                L_FLAG="-l 2"
                shift
            fi
            ;;
        -d)
            if [[ "$2" =~ ^[1-7][0-9]$|^80$|^4$|^5$|^6$|^7$|^8$|^9$ ]]; then
                D_FLAG="-d $2"
                shift
            else
                echo "Error: -d value must be between 4 and 80."
                exit 1
            fi
            ;;
        -s)
            if [[ "$2" == "ngpb" || "$2" == "zap" ]]; then
                S_FLAG="-s $2"
                if [[ "$2" == "zap" ]]; then
                    SALT_FLAG="-salt .05"
                fi
                shift
            else
                echo "Error: -s value must be 'ngpb' or 'zap'."
                exit 1
            fi
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

# Create a symbolic link named "prot.pdb"
ln -sf "$PDB_FILE" prot.pdb

echo "Symbolic link created: prot.pdb -> $PDB_FILE"

# Execute the commands sequentially with optional flags
step1.py prot.pdb $DRY_FLAG $D_FLAG
step2.py $L_FLAG $D_FLAG
step3.py $D_FLAG $S_FLAG $SALT_FLAG
step4.py --xts
