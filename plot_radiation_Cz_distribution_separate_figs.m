function plot_radiation_Cz_distribution_separate_figs(all_radiationData, domain, varargin)
% =========================================================================
% 功能：绘制算例的辐射分布和杂质离子浓度分布对比图（每个算例单独一个figure）。
%       每个figure包含1行3列子图：第1列显示总辐射分布，第2列显示Ne杂质辐射分布，第3列显示杂质离子浓度分布。
%       每组算例在子图左上角添加标识。
%       同时把各算例的辐射信息输出到一个带时间后缀的 .txt 文件中。
%       绘图后会自动保存 .fig 文件，文件名包含时间后缀，避免互相覆盖。
%       对辐射分布使用对数颜色标尺，但标尺显示的是真实值而非对数值。
%       无论domain参数如何设置，都会绘制结构。
%
%       注意：杂质离子浓度定义为 (Ne1+ + Ne2+ + ... + Ne10+) / ne，不包含中性Ne原子。
%
% 输入参数：
%   all_radiationData  - 由主脚本收集的包含各算例辐射信息的 cell 数组 (支持1个或多个算例)
%   domain             - 用户选择的绘图区域范围 (0/1/2)
%   varargin           - 可选参数（名称-值对）：
%       'ylim_mode'           - Y轴范围模式 ('preset' 或 'auto')，默认为 'preset'
%       'use_custom_colormap' - 是否使用自制colormap (mycontour.mat)，默认为 true
%       'clim_totrad'         - 总辐射colorbar范围 [min, max] (W/m³)，默认 [1e5, 1e7]
%       'clim_Ne_rad'         - Ne辐射colorbar范围 [min, max] (W/m³)，默认 [1e5, 1e7]
%       'clim_Cz'             - 杂质浓度colorbar范围 [min, max]，默认 [1e-3, 100e-3]
%
% 注意：
%   1) 需要外部自定义的函数：surfplot, plot3sep, plotstructure。
%   2) 需要确保 all_radiationData{iDir} 中含有 radInfo 结构，并具备：
%       .dirName         (string)
%       .gmtry           (网格几何信息)
%       .structure       (真空室或偏滤器结构信息)
%       .totrad_ns       (matrix) - 总辐射分布
%       .totrad_Ne       (matrix) - Ne杂质辐射分布
%       .plasma.na       (matrix) - 杂质离子密度数据，na(:,:,4:13)为Ne1+到Ne10+
%       .neut.dab        (matrix) - 中性原子密度数据，dab(:,:,2)为Ne0（杂质离子浓度计算中不使用）
%       .plasma.ne       (matrix) - 电子密度数据
%   3) MATLAB 版本需要支持 savefig 等功能。
%   4) 如果使用自制colormap，需要在当前目录或MATLAB路径中有 mycontour.mat 文件。
% =========================================================================

% 解析可选参数
p = inputParser;
addParameter(p, 'ylim_mode', 'preset', @(x) ismember(x, {'preset', 'auto'}));
addParameter(p, 'use_custom_colormap', true, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'clim_totrad', [5e5, 1e7], @(x) isnumeric(x) && numel(x) == 2 && x(1) < x(2));
addParameter(p, 'clim_Ne_rad', [5e5, 1e7], @(x) isnumeric(x) && numel(x) == 2 && x(1) < x(2));
addParameter(p, 'clim_Cz', [0, 0.05], @(x) isnumeric(x) && numel(x) == 2 && x(1) < x(2));
addParameter(p, 'cz_scale', 'linear', @(x) ismember(x, {'linear', 'log'}));
parse(p, varargin{:});
ylim_mode = p.Results.ylim_mode;
use_custom_colormap = logical(p.Results.use_custom_colormap);
clim_totrad = p.Results.clim_totrad;
clim_Ne_rad = p.Results.clim_Ne_rad;
clim_Cz = p.Results.clim_Cz;
cz_scale = p.Results.cz_scale;

% 设置全局字体为Times New Roman并增大默认字体大小
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultAxesFontSize', 16);
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultAxesFontSize', 16);
set(0, 'DefaultTextFontSize', 16);
set(0, 'DefaultLineLineWidth', 1.5);

% 检查输入数据数量并设置相应的标签
num_cases = length(all_radiationData);
if num_cases < 1
    error('This function expects at least 1 case, but received %d.', num_cases);
end

% 根据算例数量分配标签，支持多个算例
% 预定义标签，可根据需要扩展
predefined_labels = {'fav. $B_{\mathrm{T}}$', 'unfav. $B_{\mathrm{T}}$', 'Case 3', 'Case 4', 'Case 5', 'Case 6', 'Case 7', 'Case 8'};

% 如果算例数量超过预定义标签数量，自动生成标签
if num_cases > length(predefined_labels)
    for i = length(predefined_labels)+1:num_cases
        predefined_labels{i} = sprintf('Case %d', i);
    end
end

case_labels = predefined_labels(1:num_cases);  % 取前num_cases个标签

%% 1) 在所有算例中搜索各字段的全局最小/最大值，用于统一 colorbar 范围
all_totrad_ns_min = +Inf;   all_totrad_ns_max = -Inf;
all_totrad_Ne_min = +Inf;   all_totrad_Ne_max = -Inf;
all_cz_ratio_min = +Inf;    all_cz_ratio_max = -Inf;

% 遍历每个算例，更新全局 min/max
for iDir = 1:length(all_radiationData)
    radInfo = all_radiationData{iDir};
    
    % Total radiation (no-separatrix)
    all_totrad_ns_min = min(all_totrad_ns_min, min(radInfo.totrad_ns(radInfo.totrad_ns>0)));
    all_totrad_ns_max = max(all_totrad_ns_max, max(radInfo.totrad_ns(:)));
    
    % Ne radiation (no-separatrix)
    all_totrad_Ne_min = min(all_totrad_Ne_min, min(radInfo.totrad_Ne(radInfo.totrad_Ne>0)));
    all_totrad_Ne_max = max(all_totrad_Ne_max, max(radInfo.totrad_Ne(:)));
    
    % 计算杂质离子浓度（Ne1+ + Ne2+ + ... + Ne10+离子态密度 / 电子密度）
    % 注意：杂质离子浓度不包含中性粒子，只计算离子态贡献
    % Ne1+ 到 Ne10+ 的离子态密度
    impurity_ion_density = sum(radInfo.plasma.na(:,:,4:13), 3);  % Ne1+到Ne10+的总和
    
    cz_ratio = impurity_ion_density ./ radInfo.plasma.ne;  % 杂质离子浓度
    
    % 找出有效的杂质浓度值（避免除以零或非物理值）
    valid_cz = cz_ratio(isfinite(cz_ratio) & cz_ratio > 0);
    if ~isempty(valid_cz)
        all_cz_ratio_min = min(all_cz_ratio_min, min(valid_cz));
        all_cz_ratio_max = max(all_cz_ratio_max, max(valid_cz(:)));
    end
end

% 防止最小值太小导致对数标尺的问题
all_totrad_ns_min = max(all_totrad_ns_min, all_totrad_ns_max*1e-6);
all_totrad_Ne_min = max(all_totrad_Ne_min, all_totrad_Ne_max*1e-6);


%% 2) 把辐射信息输出到带时间后缀的文件中
% 生成一个时间戳
timeSuffix = datestr(now,'yyyymmdd_HHMMSS');

% 拼接输出的 txt 文件名
radInfoFilename = fullfile(pwd, ['radiation_ion_concentration_info_separate_', timeSuffix, '.txt']);

% 打开文件写入（若失败，则仅在屏幕打印）
fid = fopen(radInfoFilename, 'w');
if fid < 0
    warning('Cannot open file %s for writing. Will just print to screen.', radInfoFilename);
end

% 逐个算例打印/写入必要信息
for iDir = 1:length(all_radiationData)
    radInfo = all_radiationData{iDir};
    
    % 计算杂质离子浓度平均值和最大值
    % 注意：杂质离子浓度不包含中性粒子，只计算离子态贡献
    % Ne1+ 到 Ne10+ 的离子态密度
    impurity_ion_density = sum(radInfo.plasma.na(:,:,4:13), 3);  % Ne1+到Ne10+的总和
    
    cz_ratio = impurity_ion_density ./ radInfo.plasma.ne;
    valid_cz = cz_ratio(isfinite(cz_ratio) & cz_ratio > 0);
    avg_cz = mean(valid_cz);
    max_cz = max(valid_cz(:));
    
    % 计算Ne在内外偏滤器区域的辐射量
    % 注意：radInfo.totrad_Ne是Ne杂质辐射功率密度 (W/m³)，需要乘以体积得到总功率
    Ne_totrad = sum(sum(radInfo.totrad_Ne.*radInfo.volcell))*1e-6; % Ne总辐射功率 (MW)
    
    % 获取偏滤器区域索引（基于plot_impurity_flux_comparison_analysis.m的区域划分）
    index_div = [];
    outer_div_indices = [];
    inner_div_indices = [];
    
    if isfield(radInfo, 'gmtry') && isfield(radInfo.gmtry, 'leftcut') && isfield(radInfo.gmtry, 'rightcut')
        % 使用统一的区域划分标准（裁剪后网格96*26）
        % 外偏滤器区域：裁剪后网格中的(1-24, 1-26)
        outer_div_indices = 1:24;
        % 内偏滤器区域：裁剪后网格中的(73-96, 1-26)
        inner_div_indices = 73:size(radInfo.volcell, 1);
        index_div = [outer_div_indices, inner_div_indices];
    else
        fprintf('Warning: gmtry field or required subfields not found for case %d, skipping divertor region calculations.\n', iDir);
    end
    
    % 计算Ne在内外偏滤器区域的辐射量
    Ne_outer_div_rad = 0;
    Ne_inner_div_rad = 0;
    
    if ~isempty(outer_div_indices)
        Ne_outer_div_rad = sum(sum(radInfo.totrad_Ne(outer_div_indices,:).*radInfo.volcell(outer_div_indices,:)))*1e-6;
    end
    
    if ~isempty(inner_div_indices)
        Ne_inner_div_rad = sum(sum(radInfo.totrad_Ne(inner_div_indices,:).*radInfo.volcell(inner_div_indices,:)))*1e-6;
    end
    
    % 计算Ne辐射在外偏滤器、内偏滤器和总量中的占比
    Ne_outer_div_fraction = Ne_outer_div_rad / Ne_totrad;
    Ne_inner_div_fraction = Ne_inner_div_rad / Ne_totrad;
    Ne_div_fraction = (Ne_outer_div_rad + Ne_inner_div_rad) / Ne_totrad;
    
    % 计算Ne杂质离子在整个计算区域的总数量（密度×体积）
    % 注意：为了与杂质离子浓度定义保持一致，这里只统计离子态 (Ne1+到Ne10+)
    Ne_total_amount = 0;
    
    % Ne1+ 到 Ne10+ 的离子态数量
    for i_Z = 4:13 % Ne1+到Ne10+的索引为4到13
        % 确保使用裁剪后的数据 - na需要裁剪以匹配volcell维度
        na_sliced = radInfo.plasma.na(2:end-1, 2:end-1, i_Z);  % 排除边界网格，与volcell匹配
        Ne_total_amount = Ne_total_amount + sum(sum(na_sliced.*radInfo.volcell));
    end
    
    % 注意：不包含Ne0中性原子，以保持与杂质离子浓度定义的一致性
    
    % 计算Ne杂质在偏滤器区域的数量
    Ne_div_amount = 0;
    Ne_outer_div_amount = 0;
    Ne_inner_div_amount = 0;
    
    if ~isempty(outer_div_indices)
        % Ne1+ 到 Ne10+ 的离子态数量
        for i_Z = 4:13
            na_sliced = radInfo.plasma.na(2:end-1, 2:end-1, i_Z);  % 排除边界网格
            Ne_outer_div_amount = Ne_outer_div_amount + sum(sum(na_sliced(outer_div_indices,:).*radInfo.volcell(outer_div_indices,:)));
        end
        % 注意：不包含Ne0中性原子，以保持与杂质离子浓度定义的一致性
    end
    
    if ~isempty(inner_div_indices)
        % Ne1+ 到 Ne10+ 的离子态数量
        for i_Z = 4:13
            na_sliced = radInfo.plasma.na(2:end-1, 2:end-1, i_Z);  % 排除边界网格
            Ne_inner_div_amount = Ne_inner_div_amount + sum(sum(na_sliced(inner_div_indices,:).*radInfo.volcell(inner_div_indices,:)));
        end
        % 注意：不包含Ne0中性原子，以保持与杂质离子浓度定义的一致性
    end
    
    Ne_div_amount = Ne_outer_div_amount + Ne_inner_div_amount;
    
    % 计算Ne杂质在偏滤器区域的占比（避免除零错误）
    if Ne_total_amount > 0
        Ne_div_amount_fraction = Ne_div_amount / Ne_total_amount;
        Ne_outer_div_amount_fraction = Ne_outer_div_amount / Ne_total_amount;
        Ne_inner_div_amount_fraction = Ne_inner_div_amount / Ne_total_amount;
    else
        Ne_div_amount_fraction = 0;
        Ne_outer_div_amount_fraction = 0;
        Ne_inner_div_amount_fraction = 0;
    end
    
    % ------ 新增：定义主SOL层和芯部边缘区域索引（基于plot_impurity_flux_comparison_analysis.m的区域划分）------
    main_SOL_indices = [];
    core_edge_indices = [];
    
    if isfield(radInfo, 'gmtry') && isfield(radInfo.gmtry, 'leftcut') && isfield(radInfo.gmtry, 'rightcut') && isfield(radInfo.gmtry, 'topcut')
        % 使用统一的区域划分标准（裁剪后网格96*26）
        % 主SOL区域：裁剪后网格中的(25-72, 13-26)
        main_sol_pol_range = 25:72;
        main_sol_rad_range = 13:size(radInfo.volcell, 2);  % 13到最后一个径向网格
        
        % 创建主SOL层索引矩阵
        for ix = main_sol_pol_range
            for jy = main_sol_rad_range
                if ix <= size(radInfo.volcell, 1) && jy <= size(radInfo.volcell, 2)
                    main_SOL_indices = [main_SOL_indices; ix jy];
                end
            end
        end
        
        % 芯部区域：裁剪后网格中的(25-72, 1-12)
        core_pol_range = 25:72;
        core_rad_range = 1:12;
        
        % 创建芯部边缘区域索引矩阵
        for ix = core_pol_range
            for jy = core_rad_range
                if ix <= size(radInfo.volcell, 1) && jy <= size(radInfo.volcell, 2)
                    core_edge_indices = [core_edge_indices; ix jy];
                end
            end
        end
    end
    
    % ------ 新增：计算主SOL层的Ne粒子数和辐射量 ------
    Ne_main_SOL_amount = 0;
    Ne_main_SOL_rad = 0;
    
    if ~isempty(main_SOL_indices)
        % 计算主SOL层的Ne离子粒子数
        % Ne1+ 到 Ne10+ 的离子态数量
        for i_Z = 4:13
            na_sliced = radInfo.plasma.na(2:end-1, 2:end-1, i_Z);  % 排除边界网格
            for i = 1:size(main_SOL_indices, 1)
                ix = main_SOL_indices(i, 1);
                jy = main_SOL_indices(i, 2);
                if ix <= size(na_sliced, 1) && jy <= size(na_sliced, 2)
                    Ne_main_SOL_amount = Ne_main_SOL_amount + na_sliced(ix, jy) * radInfo.volcell(ix, jy);
                end
            end
        end
        
        % 注意：不包含Ne0中性原子，以保持与杂质离子浓度定义的一致性
        
        % 计算主SOL层的Ne辐射量
        for i = 1:size(main_SOL_indices, 1)
            ix = main_SOL_indices(i, 1);
            jy = main_SOL_indices(i, 2);
            if ix <= size(radInfo.totrad_Ne, 1) && jy <= size(radInfo.totrad_Ne, 2)
                Ne_main_SOL_rad = Ne_main_SOL_rad + radInfo.totrad_Ne(ix, jy) * radInfo.volcell(ix, jy);
            end
        end
        Ne_main_SOL_rad = Ne_main_SOL_rad * 1e-6;  % 转换为MW
    end
    
    % 计算主SOL层的Ne粒子数和辐射量占比（避免除零错误）
    if Ne_total_amount > 0
        Ne_main_SOL_amount_fraction = Ne_main_SOL_amount / Ne_total_amount;
    else
        Ne_main_SOL_amount_fraction = 0;
    end
    
    if Ne_totrad > 0
        Ne_main_SOL_rad_fraction = Ne_main_SOL_rad / Ne_totrad;
    else
        Ne_main_SOL_rad_fraction = 0;
    end
    
    % ------ 新增：计算芯部边缘区域的Ne粒子数和辐射量 ------
    Ne_core_edge_amount = 0;
    Ne_core_edge_rad = 0;
    
    if ~isempty(core_edge_indices)
        % 计算芯部边缘区域的Ne离子粒子数
        % Ne1+ 到 Ne10+ 的离子态粒子数
        for i_Z = 4:13
            na_sliced = radInfo.plasma.na(2:end-1, 2:end-1, i_Z);  % 排除边界网格
            for i = 1:size(core_edge_indices, 1)
                ix = core_edge_indices(i, 1);
                jy = core_edge_indices(i, 2);
                if ix <= size(na_sliced, 1) && jy <= size(na_sliced, 2)
                    Ne_core_edge_amount = Ne_core_edge_amount + na_sliced(ix, jy) * radInfo.volcell(ix, jy);
                end
            end
        end
        
        % 注意：不包含Ne0中性原子，以保持与杂质离子浓度定义的一致性
        
        
        % 计算芯部边缘区域的Ne辐射量
        for i = 1:size(core_edge_indices, 1)
            ix = core_edge_indices(i, 1);
            jy = core_edge_indices(i, 2);
            if ix <= size(radInfo.totrad_Ne, 1) && jy <= size(radInfo.totrad_Ne, 2)
                Ne_core_edge_rad = Ne_core_edge_rad + radInfo.totrad_Ne(ix, jy) * radInfo.volcell(ix, jy);
            end
        end
        Ne_core_edge_rad = Ne_core_edge_rad * 1e-6;  % 转换为MW
    else
        fprintf('Warning: gmtry field or required subfields not found for case %d, skipping SOL and core-edge calculations.\n', iDir);
        % 设置默认值
        Ne_main_SOL_amount = 0;
        Ne_main_SOL_rad = 0;
        Ne_core_edge_amount = 0;
        Ne_core_edge_rad = 0;
    end
    
    % 计算芯部边缘区域的Ne粒子数和辐射量占比（避免除零错误）
    if Ne_total_amount > 0
        Ne_core_edge_amount_fraction = Ne_core_edge_amount / Ne_total_amount;
    else
        Ne_core_edge_amount_fraction = 0;
    end
    
    if Ne_totrad > 0
        Ne_core_edge_rad_fraction = Ne_core_edge_rad / Ne_totrad;
    else
        Ne_core_edge_rad_fraction = 0;
    end
    
    % 屏幕打印
    fprintf('\nCase %d (%s): %s\n', iDir, case_labels{min(iDir, length(case_labels))}, radInfo.dirName);
    fprintf('\tTotal radiation power:   %2.3f MW\n', radInfo.totrad);
    fprintf('\tNe radiation power:      %2.3f MW\n', Ne_totrad);
    fprintf('\tNe outer divertor radiation: %2.3f MW (%2.1f%%)\n', Ne_outer_div_rad, Ne_outer_div_fraction*100);
    fprintf('\tNe inner divertor radiation: %2.3f MW (%2.1f%%)\n', Ne_inner_div_rad, Ne_inner_div_fraction*100);
    fprintf('\tNe total divertor radiation: %2.3f MW (%2.1f%%)\n', Ne_outer_div_rad + Ne_inner_div_rad, Ne_div_fraction*100);
    fprintf('\tNe main SOL radiation: %2.3f MW (%2.1f%%)\n', Ne_main_SOL_rad, Ne_main_SOL_rad_fraction*100);
    fprintf('\tNe core edge radiation: %2.3f MW (%2.1f%%)\n', Ne_core_edge_rad, Ne_core_edge_rad_fraction*100);
    fprintf('\tDivertor radiation power: %2.3f MW\n', radInfo.totrad_div);
    fprintf('\tDivertor radiation fraction: %2.3f\n', radInfo.div_fraction);
    fprintf('\tNe ion total amount: %2.3e particles\n', Ne_total_amount);
    fprintf('\tNe ions in outer divertor: %2.3e particles (%2.1f%%)\n', Ne_outer_div_amount, Ne_outer_div_amount_fraction*100);
    fprintf('\tNe ions in inner divertor: %2.3e particles (%2.1f%%)\n', Ne_inner_div_amount, Ne_inner_div_amount_fraction*100);
    fprintf('\tNe ions in total divertor: %2.3e particles (%2.1f%%)\n', Ne_div_amount, Ne_div_amount_fraction*100);
    fprintf('\tNe ions in main SOL: %2.3e particles (%2.1f%%)\n', Ne_main_SOL_amount, Ne_main_SOL_amount_fraction*100);
    fprintf('\tNe ions in core edge: %2.3e particles (%2.1f%%)\n', Ne_core_edge_amount, Ne_core_edge_amount_fraction*100);
    fprintf('\tAverage impurity ion concentration: %2.3e\n', avg_cz);
    fprintf('\tMaximum impurity ion concentration: %2.3e\n', max_cz);
    
    % 写入到文件
    if fid >= 0
        fprintf(fid, '\nCase %d (%s): %s\n', iDir, case_labels{min(iDir, length(case_labels))}, radInfo.dirName);
        fprintf(fid, '\tTotal radiation power:   %2.3f MW\n', radInfo.totrad);
        fprintf(fid, '\tNe radiation power:      %2.3f MW\n', Ne_totrad);
        fprintf(fid, '\tNe outer divertor radiation: %2.3f MW (%2.1f%%)\n', Ne_outer_div_rad, Ne_outer_div_fraction*100);
        fprintf(fid, '\tNe inner divertor radiation: %2.3f MW (%2.1f%%)\n', Ne_inner_div_rad, Ne_inner_div_fraction*100);
        fprintf(fid, '\tNe total divertor radiation: %2.3f MW (%2.1f%%)\n', Ne_outer_div_rad + Ne_inner_div_rad, Ne_div_fraction*100);
        fprintf(fid, '\tNe main SOL radiation: %2.3f MW (%2.1f%%)\n', Ne_main_SOL_rad, Ne_main_SOL_rad_fraction*100);
        fprintf(fid, '\tNe core edge radiation: %2.3f MW (%2.1f%%)\n', Ne_core_edge_rad, Ne_core_edge_rad_fraction*100);
        fprintf(fid, '\tDivertor radiation power: %2.3f MW\n', radInfo.totrad_div);
        fprintf(fid, '\tDivertor radiation fraction: %2.3f\n', radInfo.div_fraction);
        fprintf(fid, '\tNe ion total amount: %2.3e particles\n', Ne_total_amount);
        fprintf(fid, '\tNe ions in outer divertor: %2.3e particles (%2.1f%%)\n', Ne_outer_div_amount, Ne_outer_div_amount_fraction*100);
        fprintf(fid, '\tNe ions in inner divertor: %2.3e particles (%2.1f%%)\n', Ne_inner_div_amount, Ne_inner_div_amount_fraction*100);
        fprintf(fid, '\tNe ions in total divertor: %2.3e particles (%2.1f%%)\n', Ne_div_amount, Ne_div_amount_fraction*100);
        fprintf(fid, '\tNe ions in main SOL: %2.3e particles (%2.1f%%)\n', Ne_main_SOL_amount, Ne_main_SOL_amount_fraction*100);
        fprintf(fid, '\tNe ions in core edge: %2.3e particles (%2.1f%%)\n', Ne_core_edge_amount, Ne_core_edge_amount_fraction*100);
        fprintf(fid, '\tAverage impurity ion concentration: %2.3e\n', avg_cz);
        fprintf(fid, '\tMaximum impurity ion concentration: %2.3e\n', max_cz);
    end
end

% 如果文件成功打开，则 fclose 并提示
if fid >= 0
    fclose(fid);
    fprintf('\nRadiation and impurity ion concentration info has been written to: %s\n', radInfoFilename);
end


%% 3) 为每个算例创建单独的figure，绘制辐射和杂质浓度分布图

% 循环处理每个算例
for iDir = 1:num_cases
    
    radInfo = all_radiationData{iDir};
    
    % 计算杂质离子浓度
    % 注意：杂质离子浓度不包含中性粒子，只计算离子态贡献
    % Ne1+ 到 Ne10+ 的离子态密度
    impurity_ion_density = sum(radInfo.plasma.na(:,:,4:13), 3);  % Ne1+到Ne10+的总和
    
    cz_ratio = impurity_ion_density ./ radInfo.plasma.ne;
    
    % 处理无效值
    cz_ratio(~isfinite(cz_ratio) | cz_ratio <= 0) = NaN;
    % 根据 cz_scale 处理杂质浓度数据
    if strcmp(cz_scale, 'log')
        % 对杂质浓度数据取对数（处理零值）
        plot_cz_data = log10(max(cz_ratio, all_cz_ratio_min));
    else
        % 线性标尺
        plot_cz_data = cz_ratio;
    end
    
    % 对总辐射数据取对数（处理零值）
    log_totrad_ns = log10(max(radInfo.totrad_ns, all_totrad_ns_min));
    
    % 对Ne辐射数据取对数（处理零值）
    log_totrad_Ne = log10(max(radInfo.totrad_Ne, all_totrad_Ne_min));
    
    % 创建新的figure（每个算例一个figure）
    fig_width = 18;  % 1行3列布局，宽度较大
    fig_height = 5;  % 单行布局，高度较小
    
    fig = figure('Name', sprintf('Radiation and Impurity Ion Concentration - Case %d', iDir), ...
        'NumberTitle', 'off', ...
        'Color', 'w', ...  % 白色背景
        'Units', 'inches', ...
        'Position', [1, 1, fig_width, fig_height]); % 1行3列布局
    
    %% (1) 第1列：总辐射分布
    subplot(1, 3, 1)
    surfplot(radInfo.gmtry, log_totrad_ns);
    shading interp; view(2);
    hold on;
    plot3sep(radInfo.gmtry, 'color', 'k', 'LineStyle', '--', 'LineWidth', 1.5);
    
    % 设置colormap
    if use_custom_colormap
        try
            load('mycontour.mat', 'mycontour');
            colormap(gca, mycontour);
        catch ME
            warning(ME.identifier, 'Failed to load mycontour.mat: %s. Using default jet colormap.', ME.message);
            colormap(gca, jet);
        end
    else
        colormap(gca, jet);
    end
    
    % 统一色标（使用用户指定或默认范围）
    caxis([log10(clim_totrad(1)), log10(clim_totrad(2))]);
    
    % 创建自定义颜色条，使用简化的科学计数法
    cb = colorbar;
    
    % 计算共同的指数基数，简化显示
    exp_max = floor(log10(clim_totrad(2))-2);
    scale_factor = 10^exp_max;
    
    % 计算对数刻度位置
    log_ticks = linspace(log10(clim_totrad(1)), log10(clim_totrad(2)), 4);
    % 转换回原始值并除以缩放因子
    real_ticks = 10.^log_ticks / scale_factor;
    
    % 设置刻度和标签 - 使用%.2f确保至少两位有效数字
    set(cb, 'Ticks', log_ticks, 'TickLabels', arrayfun(@(x) sprintf('%.2f', x), real_ticks, 'UniformOutput', false), ...
        'FontName', 'Times New Roman', 'FontSize', 14);
    
    % 在colorbar上方添加单位和幂次
    title(cb, ['$\times10^{', num2str(exp_max), '}$'], 'FontName', 'Times New Roman', 'FontSize', 14, 'Interpreter', 'latex');
    
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 16, 'Box', 'on', 'LineWidth', 1.2);
    xlabel('$R$ (m)', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'latex');
    ylabel('$Z$ (m)', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'latex');
    title('$P_{rad}$ (W/m$^3$)', 'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');
    axis equal; box on;
    
    % 在右上角添加case标签
    % 根据domain参数调整文本位置
    if domain == 1
        text_x_pos = 0.95;  % domain=1时向右移动
    else
        text_x_pos = 0.75;  % 其他domain保持原位置
    end
    text(text_x_pos, 0.95, case_labels{min(iDir, length(case_labels))}, 'Units', 'normalized', ...
        'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'Interpreter', 'latex');
    
    % 根据domain参数裁剪坐标范围，并始终绘制结构
    if domain == 0
        xlim([1.20, 2.50]); ylim([-0.80, 1.20]);
    elseif domain == 1
        xlim([1.30, 2.00]); ylim([0.50, 1.20]);
    elseif domain == 2
        xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
    end
    % 始终绘制结构
    plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
    
    %% (2) 第2列：Ne杂质辐射分布
    subplot(1, 3, 2)
    surfplot(radInfo.gmtry, log_totrad_Ne);
    shading interp; view(2);
    hold on;
    plot3sep(radInfo.gmtry, 'color', 'k', 'LineStyle', '--', 'LineWidth', 1.5);
    
    % 设置colormap
    if use_custom_colormap
        try
            load('mycontour.mat', 'mycontour');
            colormap(gca, mycontour);
        catch ME
            warning(ME.identifier, 'Failed to load mycontour.mat: %s. Using default jet colormap.', ME.message);
            colormap(gca, jet);
        end
    else
        colormap(gca, jet);
    end
    
    % 统一色标（使用用户指定或默认范围）
    caxis([log10(clim_Ne_rad(1)), log10(clim_Ne_rad(2))]);
    
    % 创建自定义颜色条，使用简化的科学计数法
    cb = colorbar;
    
    % 计算共同的指数基数，简化显示
    exp_max = floor(log10(clim_Ne_rad(2))-2);
    scale_factor = 10^exp_max;
    
    % 计算对数刻度位置
    log_Ne_ticks = linspace(log10(clim_Ne_rad(1)), log10(clim_Ne_rad(2)), 4);
    % 转换回原始值并除以缩放因子
    real_Ne_ticks = 10.^log_Ne_ticks / scale_factor;
    
    % 设置刻度和标签 - 使用%.2f确保至少两位有效数字
    set(cb, 'Ticks', log_Ne_ticks, 'TickLabels', arrayfun(@(x) sprintf('%.2f', x), real_Ne_ticks, 'UniformOutput', false), ...
        'FontName', 'Times New Roman', 'FontSize', 14);
    
    % 在colorbar上方添加单位和幂次
    title(cb, ['$\times10^{', num2str(exp_max), '}$'], 'FontName', 'Times New Roman', 'FontSize', 14, 'Interpreter', 'latex');
    
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 16, 'Box', 'on', 'LineWidth', 1.2);
    xlabel('$R$ (m)', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'latex');
    ylabel('$Z$ (m)', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'latex');
    title('$P_{rad,Ne}$ (W/m$^3$)', 'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');
    axis equal; box on;
    
    % 在右上角添加case标签
    % 根据domain参数调整文本位置
    if domain == 1
        text_x_pos = 0.95;  % domain=1时向右移动
    else
        text_x_pos = 0.75;  % 其他domain保持原位置
    end
    text(text_x_pos, 0.95, case_labels{min(iDir, length(case_labels))}, 'Units', 'normalized', ...
        'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'Interpreter', 'latex');
    
    % 根据domain参数裁剪坐标范围，并始终绘制结构
    if domain == 0
        xlim([1.20, 2.50]); ylim([-0.80, 1.20]);
    elseif domain == 1
        xlim([1.30, 2.00]); ylim([0.50, 1.20]);
    elseif domain == 2
        xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
    end
    % 始终绘制结构
    plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
    
    %% (3) 第3列：杂质浓度分布
    subplot(1, 3, 3)
    surfplot(radInfo.gmtry, plot_cz_data);
    shading interp; view(2);
    hold on;
    plot3sep(radInfo.gmtry, 'color', 'k', 'LineStyle', '--', 'LineWidth', 1.5);
    
    % 设置colormap
    if use_custom_colormap
        try
            load('mycontour.mat', 'mycontour');
            colormap(gca, mycontour);
        catch ME
            warning(ME.identifier, 'Failed to load mycontour.mat: %s. Using default jet colormap.', ME.message);
            colormap(gca, jet);
        end
    else
        colormap(gca, jet);
    end
    % 设置统一的色标范围（使用用户指定或默认范围）
    if strcmp(cz_scale, 'log')
        caxis([log10(clim_Cz(1)), log10(clim_Cz(2))]);
    else
        caxis(clim_Cz);
    end
    
    % 创建自定义颜色条
    cb = colorbar;
    
    if strcmp(cz_scale, 'log')
        % 对数标尺的处理逻辑
        % 计算共同的指数基数，简化显示
        exp_min = floor(log10(clim_Cz(1)));
        scale_factor = 10^exp_min;
        
        % 计算对数刻度位置
        log_cz_ticks = linspace(log10(clim_Cz(1)), log10(clim_Cz(2)), 4);
        % 转换回原始值并除以缩放因子
        real_cz_ticks = 10.^log_cz_ticks / scale_factor;
        
        % 设置刻度和标签
        set(cb, 'Ticks', log_cz_ticks, 'TickLabels', arrayfun(@(x) sprintf('%.2f', x), real_cz_ticks, 'UniformOutput', false), ...
            'FontName', 'Times New Roman', 'FontSize', 14);
        
        % 在colorbar上方添加单位和幂次
        title(cb, ['$\times10^{', num2str(exp_min), '}$'], 'FontName', 'Times New Roman', 'FontSize', 14, 'Interpreter', 'latex');
    else
        % 线性标尺的处理逻辑
        % 自动设置刻度，或者根据范围设置
        % 为了美观，可以使用科学计数法如果数值很小
        
        % 如果最大值小于0.1，可能需要科学计数法或者百分比？
        % 这里简单处理，直接显示数值，或者根据量级调整
        
        set(cb, 'FontName', 'Times New Roman', 'FontSize', 14);
        
        % 如果需要类似对数那样的指数标记，可以手动添加，但线性通常直接显示
        % 这里保持默认线性刻度即可，或者稍微优化一下格式
    end
    
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 16, 'Box', 'on', 'LineWidth', 1.2);
    xlabel('$R$ (m)', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'latex');
    ylabel('$Z$ (m)', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'latex');
    title('$c_{Ne}$', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'latex');
    axis equal; box on;
    
    % 在右上角添加case标签
    % 根据domain参数调整文本位置
    if domain == 1
        text_x_pos = 0.95;  % domain=1时向右移动
    else
        text_x_pos = 0.75;  % 其他domain保持原位置
    end
    text(text_x_pos, 0.95, case_labels{min(iDir, length(case_labels))}, 'Units', 'normalized', ...
        'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'Interpreter', 'latex');
    
    % 根据domain参数裁剪坐标范围，并始终绘制结构
    if domain == 0
        xlim([1.20, 2.50]); ylim([-0.80, 1.20]);
    elseif domain == 1
        xlim([1.30, 2.00]); ylim([0.50, 1.20]);
    elseif domain == 2
        xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
    end
    % 始终绘制结构
    plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
    
    %% 4) 保存图形到 .fig 文件
    figFilename = sprintf('RadiationAndIonConcentration_Case%d_%s_%s', iDir, case_labels{min(iDir, length(case_labels))}, timeSuffix);
    % 移除LaTeX格式字符，避免文件名问题
    figFilename = strrep(figFilename, '$', '');
    figFilename = strrep(figFilename, '\', '');
    figFilename = strrep(figFilename, '{', '');
    figFilename = strrep(figFilename, '}', '');
    figFilename = strrep(figFilename, '_', '');
    figFilename = strrep(figFilename, 'mathrm', '');
    figFilename = strrep(figFilename, ' ', '_');
    figFilename = strrep(figFilename, '.', '');
    
    figFullPath = fullfile(pwd, [figFilename, '.fig']);
    savefig(fig, figFullPath);
    
    fprintf('Figure for Case %d has been saved to: %s\n', iDir, figFullPath);
end

fprintf('\nAll figures have been created and saved successfully.\n');
end

