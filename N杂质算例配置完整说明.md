# N杂质算例配置完整说明

## 概述

基于您提供的实际目录树文件 `directory_tree_output_20250825_172658.txt`，我已经为N杂质分析系统创建了完整的支持文件。这些文件支持主脚本 `SOLPS_Main_PostProcessing_pol_num_N.m` 的所有功能，包括高级灵活筛选系统。

## 文件结构

### 主要配置文件

1. **`predefined_case_groups_N.m`** - 主配置入口
   - 调用实际的配置函数
   - 保持与Ne脚本的接口一致性

2. **`predefined_case_groups_N_real.m`** - 实际配置实现
   - 基于真实目录结构的算例路径
   - 包含完整的fav/unfav BT分组
   - 按N浓度（0.5, 1.0, 1.5, 2.0）分类

### 高级筛选系统文件

3. **`advanced_flexible_filtering_N.m`** - N杂质专用高级筛选主函数
4. **`execute_filtering_and_grouping_N.m`** - 执行筛选和分组的核心函数
5. **`get_all_case_data_N.m`** - 获取所有N杂质算例数据
6. **`filter_cases_N.m`** - 根据条件筛选算例
7. **`group_cases_N.m`** - 根据分组依据对算例进行分组

### 测试和文档文件

8. **`test_N_script_functions.m`** - 功能测试脚本
9. **`README_N脚本更新说明.md`** - 详细更新说明
10. **`N杂质算例配置完整说明.md`** - 本文档

## 实际目录结构分析

### 基础路径
```
81574_D+N/
```

### 主要功率/密度目录
- `5p5mw_flux_1p0415e22` / `5p5mw_flux_1p1260e22` / `5p5mw_density_2p475e19`
- `6mw_density_2p7e19` / `6mw_flux_1p0720e22` / `6mw_flux_1p1747e22`
- `7mw_flux_1p1230e22` / `7mw_density_3p15e19` / `7mw_flux_1p2357e22`
- `8mw_flux_1p2738e22` / `8mw_flux_1p1541e22` / `8mw_density_3p6e19`
- `10mw_flux_1p3080e22` / `10mw_flux_1p2882e22` / `10mw_density_4p5e19` / `10mw_flux_1p300e22` / `10mw_flux_1p3000e22`

### BT方向分类
- **fav BT (有利)**: `normal` 方向算例
- **unfav BT (不利)**: `reversed` 方向算例

### N浓度分类
- **N 0.5**: 包含 `N0p5` 或 `N0_5` 的算例
- **N 1.0**: 包含 `changeto_N1` 但不含 `N1p5` 的算例
- **N 1.5**: 包含 `N1p5` 或 `N1_5` 的算例
- **N 2.0**: 包含 `changeto_N2` 或 `N2_` 的算例

## 算例路径示例

### fav BT (normal方向) 算例示例

#### N 0.5 浓度组
```matlab
'81574_D+N/5p5mw_flux_1p0415e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5'
'81574_D+N/7mw_flux_1p1230e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5'
'81574_D+N/8mw_flux_1p1541e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5'
```

#### N 1.0 浓度组
```matlab
'81574_D+N/5p5mw_flux_1p0415e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1'
'81574_D+N/7mw_flux_1p1230e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N1'
'81574_D+N/8mw_flux_1p1541e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1'
```

### unfav BT (reversed方向) 算例示例

#### N 0.5 浓度组
```matlab
'81574_D+N/8mw_flux_1p2738e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5'
'81574_D+N/5p5mw_flux_1p1260e22/baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N0p5'
'81574_D+N/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5'
```

#### N 1.0 浓度组
```matlab
'81574_D+N/8mw_flux_1p2738e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1'
'81574_D+N/5p5mw_flux_1p1260e22/baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N1_2'
'81574_D+N/10mw_flux_1p3080e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N1'
```

## 使用方法

### 1. 基本使用
```matlab
cd N脚本
SOLPS_Main_PostProcessing_pol_num_N
```

### 2. 选择方法3（高级灵活筛选）
1. 运行脚本后选择方法3
2. 按步骤选择：
   - BT方向：fav, unfav, 或 fav+unfav
   - N浓度：单个值、组合值或全部
   - 功率：单个值、组合值或全部
3. 选择分组依据
4. 确认配置并执行

### 3. 测试功能
```matlab
cd N脚本
test_N_script_functions  % 运行测试脚本验证功能
```

## 路径配置说明

### 服务器路径配置
在实际使用时，需要修改 `predefined_case_groups_N_real.m` 中的 `base_path` 变量：

```matlab
% 当前设置（需要根据实际服务器路径修改）
base_path = '81574_D+N';

% 实际服务器路径示例
base_path = '/path/to/your/server/81574_D+N';
```

### 路径验证
系统会自动验证所有路径的存在性，如果发现无效路径会提示用户选择是否继续。

## 算例统计

根据目录树分析，N杂质算例包含：

### 按BT方向分类
- **fav BT (normal)**: 约40+个算例
- **unfav BT (reversed)**: 约80+个算例

### 按N浓度分类
- **N 0.5**: 约30个算例
- **N 1.0**: 约40个算例  
- **N 1.5**: 约30个算例
- **N 2.0**: 约20个算例

### 按功率分类
- **5.5MW**: 约30个算例
- **6MW**: 约25个算例
- **7MW**: 约35个算例
- **8MW**: 约20个算例
- **10MW**: 约30个算例

## 特殊算例处理

### 变体算例
系统自动处理常见的算例变体：
- `_drift_off`, `_drift_off_2`, `_drift_off_3`, `_drift_off_4`
- `_target1`, `_target1_target1`
- `_N1p5_target1`, `_N1p5_target1_target1`
- `_cpdata44`, `_N2_target1`, `_N2_target1_target1`

### 特殊命名模式
- `changeto_N0_10_changeto_N0_4` 系列算例
- `Flux1p08e22`, `Flux1p15e22`, `Flux1p20e22`, `Flux1p26e22` 系列算例

## 维护说明

### 添加新算例
1. 在 `predefined_case_groups_N_real.m` 中添加新的算例路径
2. 确保路径格式正确
3. 运行测试脚本验证

### 修改分类逻辑
如需修改N浓度或BT方向的分类逻辑，请修改：
- `classify_cases_by_bt_direction()` 函数
- `group_cases_by_n_concentration()` 函数

### 扩展功能
可以通过修改高级筛选系统添加新的筛选维度，如密度、通量等参数。

## 注意事项

1. **路径格式**: 使用 `fullfile()` 函数确保跨平台兼容性
2. **大小写敏感**: 路径匹配区分大小写
3. **特殊字符**: 路径中的点号需要转义（如 `5\.5MW`）
4. **内存管理**: 大量算例时注意MATLAB内存使用
5. **错误处理**: 系统包含完整的错误处理和用户提示

## 技术支持

如遇到问题，请检查：
1. 路径配置是否正确
2. 算例目录是否存在
3. MATLAB版本兼容性
4. 运行测试脚本诊断问题

更多详细信息请参考 `README_N脚本更新说明.md`。
