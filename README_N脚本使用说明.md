# N脚本使用说明

## 概述

本目录包含处理充N（氮）杂质的SOLPS-ITER仿真数据的主脚本，基于充Ne主脚本修改而来。脚本保留了原脚本的所有前处理与拟合分析流程，在后处理绘图阶段调用拆分的绘图脚本。

## 主要文件

### 1. SOLPS_Main_PostProcessing_pol_num_N.m
- **功能**: 处理充N杂质的SOLPS数据主脚本
- **特点**: 
  - 支持多目录批处理
  - 计算N杂质的Zeff贡献
  - 计算辐射功率分布
  - 支持硬编码算例组功能
  - 导出详细的CSV结果文件
  - 集成动态绘图系统

### 2. predefined_case_groups_N.m
- **功能**: N杂质专用的预定义算例组配置函数
- **包含**: 
  - 有利BT方向的4个N浓度子组 (0.5, 1, 1.5, 2 e20 m^-3)
  - 不利BT方向的4个N浓度子组
  - 合并组（包含所有8个子组）

## 主要功能特点

### 1. 目录选择方式
脚本提供三种目录选择方式：
1. **扫描子目录**: 自动扫描当前目录下的所有子目录
2. **手动输入路径**: 用户手动输入多个目录组路径
3. **预定义算例组**: 使用硬编码的N杂质算例组

### 2. N杂质特定计算
- **N离子态**: 支持N0到N7+共8个电离态
- **Zeff计算**: 分别计算D和N的Zeff贡献
- **辐射功率**: 计算D和N各自的辐射功率分布
- **体积加权平均**: 使用体积加权计算芯部平均值

### 3. 数据输出
脚本输出包含以下变量的CSV文件：
- 基本物理量：Prad_total, AverageZeff_core, Average_ne_core
- N杂质相关：Average_N_ion_charge_density_core, AverageZeff_N_core
- 辐射分析：Ratio_D, Ratio_imp, Div_fraction, Prad_core, Prad_main_SOL
- 辐射效率：Prad_over_ZeffMinus1, Prad_over_Pin_ZeffMinus1

### 4. 绘图系统集成
- 调用select_and_execute_plotting_scripts_2进行动态绘图
- 支持绘图脚本刷新功能
- 错误处理机制，绘图错误不影响主脚本运行

## 使用方法

### 1. 环境准备
确保MATLAB环境中已添加SOLPS-ITER相关路径：
```
/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/scripts/MatlabPostProcessing/
```

### 2. 配置预定义算例组
编辑`predefined_case_groups_N.m`文件，修改其中的路径为实际的N杂质算例目录：
```matlab
% 示例路径格式
groups.fav_BT{1} = {
    '/path/to/N_fav_BT/N_0.5e20/case1';
    '/path/to/N_fav_BT/N_0.5e20/case2';
    % ... 更多算例路径
};
```

### 3. 运行主脚本
```matlab
cd N脚本
SOLPS_Main_PostProcessing_pol_num_N
```

### 4. 选择处理方式
根据提示选择目录处理方式：
- 输入1：扫描当前目录下的子目录
- 输入2：手动输入目录路径
- 输入3：使用预定义的N杂质算例组

### 5. 绘图选项
数据处理完成后，可选择：
- 输入1：执行绘图脚本
- 输入r：刷新绘图脚本
- 输入0：退出程序

## 与Ne脚本的主要差异

1. **杂质种类**: 从Ne杂质改为N杂质
2. **电离态数量**: N杂质支持8个电离态（N0-N7+）
3. **species_variables**: 设置为10（D的2个态 + N的8个态）
4. **变量命名**: 所有相关变量从Ne改为N
5. **预定义组**: 使用专门的N杂质算例组配置

## 注意事项

1. **网格尺寸**: 脚本假设使用98×28的标准网格
2. **文件要求**: 需要b2fgmtry, fort.44, b2fstate, b2fplasmf等关键文件
3. **路径配置**: 预定义算例组的路径需要根据实际情况修改
4. **MATLAB版本**: 建议使用MATLAB 2017b或更高版本
5. **中文显示**: 服务器端MATLAB可能不支持中文显示，所有提示信息已翻译为英文

## 输出文件

- **组级CSV**: `output_results_group{N}_{timestamp}.csv`
- **总体CSV**: `output_results_{timestamp}.csv`
- **绘图文件**: 根据选择的绘图选项生成相应的.fig文件

## 故障排除

1. **路径错误**: 检查SOLPS-ITER路径配置和算例目录路径
2. **文件缺失**: 确保所有必需的SOLPS输出文件存在
3. **内存不足**: 对于大量算例，考虑分批处理
4. **绘图错误**: 使用刷新功能重新加载绘图脚本

## 扩展功能

脚本支持与现有的绘图系统集成，可以：
- 添加新的N杂质专用绘图选项
- 修改现有绘图脚本以适应N杂质数据
- 扩展预定义算例组配置
