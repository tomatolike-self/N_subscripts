# N脚本更新说明

## 概述

本次更新将N脚本（`SOLPS_Main_PostProcessing_pol_num_N.m`）与最新的Ne脚本（`SOLPS_Main_PostProcessing_pol_num.m`）保持同步，添加了高级灵活筛选功能和更多的数据收集功能。

## 主要更新内容

### 1. 高级灵活筛选系统

#### 新增文件：
- `advanced_flexible_filtering_N.m` - N杂质专用的高级筛选主函数
- `execute_filtering_and_grouping_N.m` - 执行筛选和分组的核心函数
- `get_all_case_data_N.m` - 获取所有N杂质算例数据
- `filter_cases_N.m` - 根据条件筛选算例
- `group_cases_N.m` - 根据分组依据对算例进行分组

#### 功能特性：
- **灵活选择BT方向**：fav, unfav, 或 fav+unfav
- **灵活选择N浓度**：单个值、组合值或全部（0.5, 1.0, 1.5, 2.0）
- **灵活选择功率**：单个值、组合值或全部（5.5, 6, 7, 8 MW）
- **自由分组依据**：任意变量组合作为分组维度
- **智能验证**：自动验证路径存在性和选择合理性

### 2. 新增数据收集功能

#### OMP分离面外第一个网格数据：
- `all_ne_OMP_sep_outer_collected` - 电子密度
- `all_nD_plus_OMP_sep_outer_collected` - 主离子密度
- `all_nN_total_OMP_sep_outer_collected` - N杂质离子密度总和
- `all_Te_OMP_sep_outer_collected` - 电子温度

#### 输出CSV文件新增列：
- `ne_OMP_sep_outer` - OMP分离面外第一个网格电子密度
- `nD_plus_OMP_sep_outer` - OMP分离面外第一个网格主离子密度
- `nN_total_OMP_sep_outer` - OMP分离面外第一个网格N杂质离子密度总和
- `Te_OMP_sep_outer` - OMP分离面外第一个网格电子温度

### 3. 脚本结构优化

#### 方法3更新：
- 从简单的预定义组选择升级为高级灵活筛选
- 支持复杂的组合选择和自定义分组
- 提供详细的用户引导和结果显示

#### 代码注释更新：
- 更新了脚本头部说明，添加了新功能描述
- 保持了与Ne脚本一致的注释风格
- 明确标注了N杂质特有的参数设置

### 4. N杂质特定修正

#### 物种参数：
- `species_variables = 10` - D(2个态) + N(8个态)
- N杂质电离态：N0到N7+（共8个态）
- 对应plasma.na的第3到第10维

#### 变量命名：
- 所有Ne相关变量改为N相关
- 如：`all_average_Ne_ion_charge_density_collected` → `all_average_N_ion_charge_density_collected`
- CSV输出列名相应更新

## 使用方法

### 1. 基本使用
```matlab
cd N脚本
SOLPS_Main_PostProcessing_pol_num_N
```

### 2. 选择方法3（高级灵活筛选）
1. 运行脚本后选择方法3
2. 按步骤选择BT方向、N浓度、功率
3. 选择分组依据
4. 确认配置并执行

### 3. 测试功能
```matlab
cd N脚本
test_N_script_functions  % 运行测试脚本验证功能
```

## 兼容性说明

### 向后兼容：
- ✅ 方法1和方法2保持不变
- ✅ 原有的预定义组功能仍然可用
- ✅ 输出格式兼容现有分析流程

### 依赖要求：
- MATLAB 2017b或更高版本
- 需要正确配置SOLPS-ITER路径
- 需要有效的N杂质算例数据

## 注意事项

1. **路径配置**：确保`predefined_case_groups_N.m`中的路径指向实际的N杂质算例目录
2. **数据验证**：新的筛选系统会自动验证路径存在性
3. **错误处理**：增强了错误处理机制，筛选失败不会中断主脚本
4. **性能优化**：预分配了数组以提高大数据集处理性能

## 测试验证

运行`test_N_script_functions.m`可以验证：
- ✅ 预定义算例组加载
- ✅ 数据获取功能
- ✅ 筛选功能
- ✅ 分组功能
- ✅ 函数存在性检查

## 与Ne脚本的差异

| 特性 | Ne脚本 | N脚本 |
|------|--------|-------|
| 杂质种类 | Ne | N |
| 电离态数量 | 11个（Ne0-Ne10+） | 8个（N0-N7+） |
| species_variables | 13 | 10 |
| plasma.na维度 | 第3-13维 | 第3-10维 |
| 筛选函数 | advanced_flexible_filtering | advanced_flexible_filtering_N |

## 后续维护

1. 定期同步Ne脚本的新功能
2. 根据实际使用情况优化筛选逻辑
3. 扩展支持更多N杂质相关的分析功能
4. 持续改进用户体验和错误处理
