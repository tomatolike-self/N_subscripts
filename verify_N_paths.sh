#!/bin/bash
# ========================================================================
# N杂质算例完整验证脚本
# 用于批量检查所有117个算例路径的存在性和主脚本运行依赖
# ========================================================================

echo "========================================================================"
echo "N杂质算例完整验证脚本 - 验证所有117个算例"
echo "========================================================================"
echo "开始时间: $(date)"
echo ""

# 基础路径
BASE_PATH="/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N"

# 检查基础路径是否存在
echo "1. 检查基础路径..."
if [ -d "$BASE_PATH" ]; then
    echo "✓ 基础路径存在: $BASE_PATH"
else
    echo "✗ 基础路径不存在: $BASE_PATH"
    exit 1
fi

echo ""

# 统计变量
total_paths=0
existing_paths=0
missing_paths=0
complete_cases=0
incomplete_cases=0

# 创建输出文件存储结果（保存到当前目录）
current_time=$(date +%Y%m%d_%H%M%S)
temp_file="./n_path_check_${current_time}.txt"
missing_file="./n_missing_paths_${current_time}.txt"
incomplete_file="./n_incomplete_cases_${current_time}.txt"

# 函数：检查单个算例的完整性
check_case_completeness() {
    local case_path="$1"
    local case_name=$(basename "$case_path")
    local is_complete=true
    local missing_files=()

    # 检查主脚本需要的关键文件
    local required_files=(
        "b2fgmtry"
        "fort.44"
        "b2fstate"
        "b2fplasmf"
        "b2.neutrals.parameters"
    )

    for file in "${required_files[@]}"; do
        if [ ! -f "$case_path/$file" ]; then
            missing_files+=("$file")
            is_complete=false
        fi
    done

    # 检查output目录
    if [ ! -d "$case_path/output" ]; then
        missing_files+=("output/")
        is_complete=false
    fi

    # 检查structure.dat文件（在多个可能位置）
    local structure_found=false
    local parent_dir=$(dirname "$case_path")
    local grandparent_dir=$(dirname "$parent_dir")
    local great_grandparent_dir=$(dirname "$grandparent_dir")

    # 按主脚本的查找逻辑检查structure.dat
    local possible_structure_files=(
        "$case_path/structure.dat"
        "$parent_dir/structure.dat"
        "$grandparent_dir/structure.dat"
        "$great_grandparent_dir/structure.dat"
        "/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/structure.dat"
    )

    for struct_file in "${possible_structure_files[@]}"; do
        if [ -f "$struct_file" ]; then
            structure_found=true
            break
        fi
    done

    if [ "$structure_found" = false ]; then
        missing_files+=("structure.dat")
        is_complete=false
    fi

    if [ "$is_complete" = true ]; then
        echo "  ✓ $case_name (完整)"
        complete_cases=$((complete_cases + 1))
    else
        echo "  ✗ $case_name (缺失: ${missing_files[*]})"
        echo "$case_path: 缺失文件 - ${missing_files[*]}" >> "$incomplete_file"
        incomplete_cases=$((incomplete_cases + 1))
    fi

    return $is_complete
}

# 定义所有117个算例路径
declare -a all_case_paths=(
    # FAV BT - N 0.5 组 (9个)
    "$BASE_PATH/5p5mw_flux_1p0415e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5"
    "$BASE_PATH/7mw_flux_1p1230e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5"
    "$BASE_PATH/7mw_flux_1p1230e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5_Flux1p08e22_target1"
    "$BASE_PATH/7mw_flux_1p1230e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5_Flux1p08e22_target1_target1"
    "$BASE_PATH/8mw_flux_1p1541e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5"
    "$BASE_PATH/10mw_flux_1p2882e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5"
    "$BASE_PATH/6mw_flux_1p0720e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5"
    "$BASE_PATH/6mw_flux_1p0720e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5_Flux1p15e22_target1"
    "$BASE_PATH/6mw_flux_1p0720e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5_Flux1p15e22_target1_target1"

    # FAV BT - N 1.0 组 (10个)
    "$BASE_PATH/5p5mw_flux_1p0415e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1"
    "$BASE_PATH/5p5mw_flux_1p0415e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_cpdata44"
    "$BASE_PATH/7mw_flux_1p1230e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N1"
    "$BASE_PATH/7mw_flux_1p1230e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N1_Flux1p08e22_target1"
    "$BASE_PATH/8mw_flux_1p1541e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1"
    "$BASE_PATH/10mw_flux_1p2882e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1"
    "$BASE_PATH/10mw_flux_1p2882e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_2"
    "$BASE_PATH/6mw_flux_1p0720e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1"
    "$BASE_PATH/6mw_flux_1p0720e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_Flux1p15e22_target1"
    "$BASE_PATH/6mw_flux_1p0720e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_Flux1p15e22_target1_target1"

    # FAV BT - N 1.5 组 (14个)
    "$BASE_PATH/5p5mw_flux_1p0415e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_N1p5_target1"
    "$BASE_PATH/5p5mw_flux_1p0415e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_N1p5_target1_target1"
    "$BASE_PATH/7mw_flux_1p1230e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N1_Flux1p08e22_N1p5_target1"
    "$BASE_PATH/7mw_flux_1p1230e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N1_Flux1p08e22_N1p5_target1_target1"
    "$BASE_PATH/7mw_flux_1p1230e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N1_N1p5_target1"
    "$BASE_PATH/7mw_flux_1p1230e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N1_N1p5_target1_target1"
    "$BASE_PATH/8mw_flux_1p1541e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_N1p5_target1"
    "$BASE_PATH/8mw_flux_1p1541e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_N1p5_target1_target1"
    "$BASE_PATH/10mw_flux_1p2882e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_2_N1p5_target1"
    "$BASE_PATH/10mw_flux_1p2882e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_2_N1p5_target1_target1"
    "$BASE_PATH/6mw_flux_1p0720e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_N1p5_target1"
    "$BASE_PATH/6mw_flux_1p0720e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_N1p5_target1_target1"
    "$BASE_PATH/6mw_flux_1p0720e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_Flux1p15e22_N1p5_target1"
    "$BASE_PATH/6mw_flux_1p0720e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_Flux1p15e22_N1p5_target1_target1"

    # FAV BT - N 2.0 组 (9个)
    "$BASE_PATH/5p5mw_flux_1p0415e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N2"
    "$BASE_PATH/7mw_flux_1p1230e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N2"
    "$BASE_PATH/7mw_flux_1p1230e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N2_Flux1p08e22_target1"
    "$BASE_PATH/7mw_flux_1p1230e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N2_Flux1p08e22_target1_target1"
    "$BASE_PATH/8mw_flux_1p1541e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N2"
    "$BASE_PATH/10mw_flux_1p2882e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N2"
    "$BASE_PATH/6mw_flux_1p0720e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N2"
    "$BASE_PATH/6mw_flux_1p0720e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N2_Flux1p15e22_target1"
    "$BASE_PATH/6mw_flux_1p0720e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N2_Flux1p15e22_target1_target1"

    # UNFAV BT - N 0.5 组 (22个)
    "$BASE_PATH/8mw_flux_1p2738e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5"
    "$BASE_PATH/8mw_flux_1p2738e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_drift_off"
    "$BASE_PATH/8mw_flux_1p2738e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_drift_off_2"
    "$BASE_PATH/5p5mw_flux_1p1260e22/baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N0p5"
    "$BASE_PATH/5p5mw_flux_1p1260e22/baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N0p5_drift_off"
    "$BASE_PATH/5p5mw_flux_1p1260e22/baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N0p5_drift_off_2"
    "$BASE_PATH/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5"
    "$BASE_PATH/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_drift_off"
    "$BASE_PATH/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_drift_off_2"
    "$BASE_PATH/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_Flux1p20e22_target1"
    "$BASE_PATH/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_Flux1p20e22_target1_target1"
    "$BASE_PATH/10mw_flux_1p3000e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5"
    "$BASE_PATH/10mw_flux_1p3000e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_drift_off"
    "$BASE_PATH/10mw_flux_1p3000e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_drift_off_2"
    "$BASE_PATH/10mw_flux_1p3000e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_drift_off_3"
    "$BASE_PATH/10mw_flux_1p3000e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_drift_off_4"
    "$BASE_PATH/10mw_flux_1p3000e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_target1"
    "$BASE_PATH/10mw_flux_1p3000e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_target1_target1"
    "$BASE_PATH/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5"
    "$BASE_PATH/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_drift_off"
    "$BASE_PATH/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_drift_off_2"
    "$BASE_PATH/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_Flux1p26e22_target1"
    "$BASE_PATH/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_Flux1p26e22_target1_target1"

    # UNFAV BT - N 1.0 组 (21个)
    "$BASE_PATH/8mw_flux_1p2738e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1"
    "$BASE_PATH/8mw_flux_1p2738e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_drift_off"
    "$BASE_PATH/5p5mw_flux_1p1260e22/baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N1"
    "$BASE_PATH/5p5mw_flux_1p1260e22/baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N1_2"
    "$BASE_PATH/5p5mw_flux_1p1260e22/baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N1_2_drift_off"
    "$BASE_PATH/5p5mw_flux_1p1260e22/baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N1_2_drift_off_2"
    "$BASE_PATH/5p5mw_flux_1p1260e22/baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N1_2_cpdata44"
    "$BASE_PATH/10mw_flux_1p3080e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N1"
    "$BASE_PATH/10mw_flux_1p3080e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N1_drift_off"
    "$BASE_PATH/10mw_flux_1p3080e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N1_drift_off_2"
    "$BASE_PATH/10mw_flux_1p3080e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N1_drift_off_3"
    "$BASE_PATH/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1"
    "$BASE_PATH/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_drift_off"
    "$BASE_PATH/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_drift_off_2"
    "$BASE_PATH/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p20e22_target1"
    "$BASE_PATH/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p20e22_target1_target1"
    "$BASE_PATH/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1"
    "$BASE_PATH/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_drift_off"
    "$BASE_PATH/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_drift_off_2"
    "$BASE_PATH/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p26e22_target1"
    "$BASE_PATH/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p26e22_target1_target1"

    # UNFAV BT - N 1.5 组 (14个)
    "$BASE_PATH/8mw_flux_1p2738e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_N1p5_target1"
    "$BASE_PATH/8mw_flux_1p2738e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_N1p5_target1_target1"
    "$BASE_PATH/5p5mw_flux_1p1260e22/baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N1_2_N1p5_target1"
    "$BASE_PATH/5p5mw_flux_1p1260e22/baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N1_2_N1p5_target1_target1"
    "$BASE_PATH/10mw_flux_1p3080e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N1_N1p5_target1"
    "$BASE_PATH/10mw_flux_1p3080e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N1_N1p5_target1_target1"
    "$BASE_PATH/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_N1p5_target1"
    "$BASE_PATH/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_N1p5_target1_target1"
    "$BASE_PATH/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p20e22_N1p5_target1"
    "$BASE_PATH/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p20e22_N1p5_target1_target1"
    "$BASE_PATH/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_N1p5_target1"
    "$BASE_PATH/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_N1p5_target1_target1"
    "$BASE_PATH/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p26e22_N1p5_target1"
    "$BASE_PATH/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p26e22_N1p5_target1_target1"

    # UNFAV BT - N 2.0 组 (17个)
    "$BASE_PATH/8mw_flux_1p2738e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N2"
    "$BASE_PATH/8mw_flux_1p2738e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_changeto_N2"
    "$BASE_PATH/5p5mw_flux_1p1260e22/baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N2"
    "$BASE_PATH/5p5mw_flux_1p1260e22/baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N2_2"
    "$BASE_PATH/5p5mw_flux_1p1260e22/baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N2_2_drift_off"
    "$BASE_PATH/5p5mw_flux_1p1260e22/baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N2_2_drift_off_2"
    "$BASE_PATH/10mw_flux_1p3080e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N2"
    "$BASE_PATH/10mw_flux_1p3080e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N1_N2_target1"
    "$BASE_PATH/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N2"
    "$BASE_PATH/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p20e22_N2_target1"
    "$BASE_PATH/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p20e22_N2_target1_target1"
    "$BASE_PATH/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N2"
    "$BASE_PATH/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_N2_target1"
    "$BASE_PATH/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_N2_target1_target1"
    "$BASE_PATH/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p26e22_N2_target1"
    "$BASE_PATH/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p26e22_N2_target1_target1"
    "$BASE_PATH/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N2_drift_off"
    "$BASE_PATH/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N2_drift_off_2"
)

echo "2. 检查算例列表中的重复项..."

# 检查重复路径
echo "检查重复路径..."
duplicate_paths=$(printf '%s\n' "${all_case_paths[@]}" | sort | uniq -d)
if [ -n "$duplicate_paths" ]; then
    echo "⚠ 发现重复路径:"
    echo "$duplicate_paths"
    echo "$duplicate_paths" > "./duplicate_paths_${current_time}.txt"
else
    echo "✓ 未发现重复路径"
fi

echo ""
echo "3. 开始验证所有N杂质算例..."
echo ""

# 按组分类统计
fav_n05_count=0; fav_n10_count=0; fav_n15_count=0; fav_n20_count=0
unfav_n05_count=0; unfav_n10_count=0; unfav_n15_count=0; unfav_n20_count=0

# 遍历所有算例进行验证
for i in "${!all_case_paths[@]}"; do
    path="${all_case_paths[$i]}"
    total_paths=$((total_paths + 1))

    # 确定当前算例的分类
    case_name=$(basename "$path")
    group_info=""

    if [[ "$case_name" == *"normal"* ]]; then
        bt_type="fav"
        if [[ "$case_name" == *"N0p5"* ]]; then
            group_info="fav-N0.5"
            fav_n05_count=$((fav_n05_count + 1))
        elif [[ "$case_name" == *"N1p5"* ]]; then
            group_info="fav-N1.5"
            fav_n15_count=$((fav_n15_count + 1))
        elif [[ "$case_name" == *"changeto_N2"* ]]; then
            group_info="fav-N2.0"
            fav_n20_count=$((fav_n20_count + 1))
        else
            group_info="fav-N1.0"
            fav_n10_count=$((fav_n10_count + 1))
        fi
    else
        bt_type="unfav"
        if [[ "$case_name" == *"N0p5"* ]]; then
            group_info="unfav-N0.5"
            unfav_n05_count=$((unfav_n05_count + 1))
        elif [[ "$case_name" == *"N1p5"* ]]; then
            group_info="unfav-N1.5"
            unfav_n15_count=$((unfav_n15_count + 1))
        elif [[ "$case_name" == *"changeto_N2"* ]] || [[ "$case_name" == *"N2_"* ]]; then
            group_info="unfav-N2.0"
            unfav_n20_count=$((unfav_n20_count + 1))
        else
            group_info="unfav-N1.0"
            unfav_n10_count=$((unfav_n10_count + 1))
        fi
    fi

    # 检查路径存在性
    if [ -d "$path" ]; then
        existing_paths=$((existing_paths + 1))
        printf "✓ [%03d/%03d] %-12s %s\n" $((i+1)) ${#all_case_paths[@]} "$group_info" "$(basename "$path")"

        # 检查算例完整性
        check_case_completeness "$path" > /dev/null

        # 记录所有路径到调试文件
        echo "$path" >> "./all_found_paths_${current_time}.txt"

    else
        missing_paths=$((missing_paths + 1))
        printf "✗ [%03d/%03d] %-12s %s (路径不存在)\n" $((i+1)) ${#all_case_paths[@]} "$group_info" "$(basename "$path")"
        echo "$path" >> "$missing_file"
    fi
done

echo ""
echo "4. 检查MATLAB函数依赖..."

# 检查MATLAB读取函数是否存在
matlab_functions=(
    "read_structure"
    "read_b2fgmtry"
    "read_ft44"
    "read_b2fplasmf"
)

echo "检查MATLAB读取函数:"
matlab_functions_found=0
for func in "${matlab_functions[@]}"; do
    # 在多个可能位置查找.m文件
    found=false
    search_paths=(
        "./${func}.m"
        "../${func}.m"
        "../../${func}.m"
        "../../../${func}.m"
        "/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/${func}.m"
    )

    for search_path in "${search_paths[@]}"; do
        if [ -f "$search_path" ]; then
            echo "  ✓ ${func}.m 存在 (位置: $search_path)"
            found=true
            matlab_functions_found=$((matlab_functions_found + 1))
            break
        fi
    done

    if [ "$found" = false ]; then
        echo "  ✗ ${func}.m 缺失 - 主脚本运行需要此函数"
    fi
done

echo ""
echo "5. 检查N杂质专用函数..."

# 检查N杂质专用函数
n_functions=(
    "predefined_case_groups_N"
    "advanced_flexible_filtering_N"
    "execute_filtering_and_grouping_N"
    "get_all_case_data_N"
    "filter_cases_N"
    "group_cases_N"
)

echo "检查N杂质专用函数:"
for func in "${n_functions[@]}"; do
    if [ -f "${func}.m" ]; then
        echo "  ✓ ${func}.m 存在"
    else
        echo "  ✗ ${func}.m 缺失 - 高级筛选功能需要此函数"
    fi
done

echo ""
echo "========================================================================"
echo "验证结果统计"
echo "========================================================================"
echo "总算例数: $total_paths (预期: 117)"
echo "存在算例数: $existing_paths"
echo "缺失算例数: $missing_paths"
echo "完整算例数: $complete_cases"
echo "不完整算例数: $incomplete_cases"

echo ""
echo "按组分类统计:"
echo "FAV BT 组:"
echo "  N 0.5: $fav_n05_count 个算例 (预期: 9)"
echo "  N 1.0: $fav_n10_count 个算例 (预期: 10)"
echo "  N 1.5: $fav_n15_count 个算例 (预期: 14)"
echo "  N 2.0: $fav_n20_count 个算例 (预期: 9)"
echo "  fav BT 小计: $((fav_n05_count + fav_n10_count + fav_n15_count + fav_n20_count)) (预期: 42)"

echo ""
echo "UNFAV BT 组:"
echo "  N 0.5: $unfav_n05_count 个算例 (预期: 22)"
echo "  N 1.0: $unfav_n10_count 个算例 (预期: 22)"
echo "  N 1.5: $unfav_n15_count 个算例 (预期: 14)"
echo "  N 2.0: $unfav_n20_count 个算例 (预期: 17)"
echo "  unfav BT 小计: $((unfav_n05_count + unfav_n10_count + unfav_n15_count + unfav_n20_count)) (预期: 75)"

echo ""
echo "========================================================================"
echo "问题报告"
echo "========================================================================"

if [ $missing_paths -gt 0 ]; then
    echo "⚠ 发现 $missing_paths 个缺失路径"
    echo "  详细列表已保存到: $missing_file"
    echo "  建议: 检查这些路径是否正确或从配置中移除"
fi

if [ $incomplete_cases -gt 0 ]; then
    echo "⚠ 发现 $incomplete_cases 个不完整算例"
    echo "  详细列表已保存到: $incomplete_file"
    echo "  建议: 检查缺失的SOLPS文件"
fi

# 检查总数是否匹配
if [ $total_paths -ne 117 ]; then
    echo "⚠ 算例总数不匹配: 实际 $total_paths，预期 117"
fi

# 检查各组数量是否匹配
expected_fav=$((9 + 10 + 14 + 9))
expected_unfav=$((22 + 22 + 14 + 17))
actual_fav=$((fav_n05_count + fav_n10_count + fav_n15_count + fav_n20_count))
actual_unfav=$((unfav_n05_count + unfav_n10_count + unfav_n15_count + unfav_n20_count))

if [ $actual_fav -ne $expected_fav ]; then
    echo "⚠ FAV BT组数量不匹配: 实际 $actual_fav，预期 $expected_fav"
fi

if [ $actual_unfav -ne $expected_unfav ]; then
    echo "⚠ UNFAV BT组数量不匹配: 实际 $actual_unfav，预期 $expected_unfav"
fi

echo ""
echo "========================================================================"
echo "主脚本运行就绪状态"
echo "========================================================================"

# 评估主脚本运行就绪状态
ready_score=0
total_score=5

if [ $existing_paths -gt 100 ]; then
    echo "✓ 算例路径: 大部分存在 ($existing_paths/$total_paths)"
    ready_score=$((ready_score + 1))
else
    echo "✗ 算例路径: 存在数量不足 ($existing_paths/$total_paths)"
fi

if [ $complete_cases -gt 80 ]; then
    echo "✓ 算例完整性: 大部分完整 ($complete_cases 个完整算例)"
    ready_score=$((ready_score + 1))
else
    echo "✗ 算例完整性: 完整数量不足 ($complete_cases 个完整算例)"
fi

# 检查MATLAB函数
if [ $matlab_functions_found -eq ${#matlab_functions[@]} ]; then
    echo "✓ MATLAB读取函数: 全部存在 ($matlab_functions_found/${#matlab_functions[@]})"
    ready_score=$((ready_score + 1))
elif [ $matlab_functions_found -gt 0 ]; then
    echo "⚠ MATLAB读取函数: 部分存在 ($matlab_functions_found/${#matlab_functions[@]})"
else
    echo "✗ MATLAB读取函数: 全部缺失 ($matlab_functions_found/${#matlab_functions[@]})"
fi

# 检查N杂质函数
n_ready=true
for func in "predefined_case_groups_N" "advanced_flexible_filtering_N"; do
    if [ ! -f "${func}.m" ]; then
        n_ready=false
        break
    fi
done

if [ "$n_ready" = true ]; then
    echo "✓ N杂质专用函数: 核心函数存在"
    ready_score=$((ready_score + 1))
else
    echo "✗ N杂质专用函数: 核心函数缺失"
fi

# 检查基础路径
if [ -d "$BASE_PATH" ]; then
    echo "✓ 基础路径: 可访问"
    ready_score=$((ready_score + 1))
else
    echo "✗ 基础路径: 不可访问"
fi

echo ""
echo "就绪评分: $ready_score/$total_score"

if [ $ready_score -ge 4 ]; then
    echo "✅ 主脚本基本就绪，可以尝试运行"
elif [ $ready_score -ge 2 ]; then
    echo "⚠️  主脚本部分就绪，建议修复问题后运行"
else
    echo "❌ 主脚本未就绪，需要解决关键问题"
fi

echo ""
echo "完成时间: $(date)"
echo "========================================================================"

# 清理临时文件
rm -f "$temp_file"

# 显示日志文件位置
echo "验证日志文件:"
echo "  所有找到的路径: ./all_found_paths_${current_time}.txt"
if [ -f "./duplicate_paths_${current_time}.txt" ]; then
    echo "  重复路径列表: ./duplicate_paths_${current_time}.txt"
fi
if [ $missing_paths -gt 0 ]; then
    echo "  缺失路径: $missing_file"
fi
if [ $incomplete_cases -gt 0 ]; then
    echo "  不完整算例: $incomplete_file"
fi
