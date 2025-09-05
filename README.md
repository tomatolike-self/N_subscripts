# SOLPS-ITER N脚本分析工具

这是SOLPS-ITER模拟中专门用于氮(N)杂质分析的MATLAB脚本集合。

## 概述

本仓库包含了用于分析SOLPS-ITER模拟中氮杂质行为的专用脚本，与主仓库中的氖(Ne)脚本相区分。

## 主要功能

### 数据处理和验证
- validate_and_deduplicate_cases.m - 数据验证和去重
- get_all_case_data_from_validated_groups.m - 从验证组获取案例数据
- debug_validation.m - 调试验证工具

### 绘图和分析
- plot_N_ion_distribution_and_all_density.m - N离子分布和密度分析
- plot_CoreEdge_N_Zeff_contributions.m - 核心边缘N的Zeff贡献分析
- plot_radiation_Nz_distribution.m - 辐射Nz分布
- plot_frad_imp_vs_zeff_relationship_N.m - N杂质的frad与zeff关系
- plot_N_zeff_scaling_law_fitting.m - N的Zeff标度律拟合

### 案例分组和过滤
- predefined_case_groups_N_real.m - 预定义的N案例分组
- execute_filtering_and_grouping_N.m - 执行过滤和分组
- group_cases_N.m - N案例分组
- filter_cases_N.m - N案例过滤

### 主要处理脚本
- SOLPS_Main_PostProcessing_pol_num_N.m - N脚本主要后处理程序
- select_and_execute_plotting_scripts_2.m - 选择和执行绘图脚本

## 使用说明

1. 确保MATLAB环境已正确配置
2. 设置正确的数据路径
3. 运行主处理脚本或选择特定的分析脚本

## 与主仓库的关系

本仓库作为主SOLPS分析脚本仓库的子模块，专门处理氮杂质相关的分析任务，与主仓库中的氖(Ne)脚本形成清晰的功能分离。

## 贡献

请遵循主仓库的贡献指南，确保代码质量和文档完整性。
