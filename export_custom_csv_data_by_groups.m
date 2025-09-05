function export_custom_csv_data_by_groups(all_radiationData, groupDirs, selected_groups)
% EXPORT_CUSTOM_CSV_DATA_BY_GROUPS 按组导出CSV数据文件
%   该函数按照主脚本的输出格式，导出选择组的所有变量数据
%   输出格式完全参考SOLPS_Main_PostProcessing_pol_num.m的outputTable
%
%   参数:
%     all_radiationData - 包含所有SOLPS仿真辐射数据的结构体数组
%     groupDirs - 包含分组目录信息的元胞数组
%     selected_groups - 选择的组索引数组
%
%   示例:
%     export_custom_csv_data_by_groups(all_radiationData, groupDirs, [2, 3, 5])

fprintf('\n=== 自定义CSV数据输出（按组选择）===\n');

% 初始化数据收集变量（完全按照主脚本格式）
export_data = struct();

% 主脚本中的所有变量（按照outputTable的顺序）
export_data.Directory = {};                              % 目录
export_data.Prad_total = [];                            % 总辐射功率
export_data.AverageZeff_core = [];                      % 芯部平均Zeff
export_data.Average_ne_core = [];                       % 芯部平均电子密度
export_data.Ne2_core = [];                              % 芯部电子密度平方
export_data.Average_nD_plus_poloidal = [];              % 极向平均D+密度
export_data.Average_Ne_ion_charge_density_core = [];    % 芯部平均Ne离子带电密度
export_data.Ptot = [];                                  % 总输入功率
export_data.Prad_vs_Ptot = [];                          % 辐射功率占比
export_data.Prad_over_ZeffMinus1 = [];                  % Prad/(Zeff-1)
export_data.Prad_over_Pin_ZeffMinus1 = [];              % Prad/(Pin*(Zeff-1))
export_data.fna_core_D_plus = [];                       % 芯部D+通量
export_data.Ratio_D = [];                               % D辐射占比
export_data.Ratio_imp = [];                             % 杂质辐射占比
export_data.Div_fraction = [];                          % 偏滤器区辐射占比
export_data.Prad_core = [];                             % 芯部辐射功率
export_data.Prad_main_SOL = [];                         % 主SOL辐射功率
export_data.AverageZeff_D_core = [];                    % 芯部平均Zeff_D
export_data.AverageZeff_Ne_core = [];                   % 芯部平均Zeff_Ne

% 建立all_radiationData索引到组的映射
data_to_group_map = containers.Map('KeyType', 'int32', 'ValueType', 'int32');
global_index = 0;
for g = 1:length(groupDirs)
    for dir_idx = 1:length(groupDirs{g})
        global_index = global_index + 1;
        if global_index <= length(all_radiationData) && ~isempty(all_radiationData{global_index})
            data_to_group_map(global_index) = g;
        end
    end
end

% 从选择的组中提取数据
total_cases_exported = 0;
for g = selected_groups
    if g > length(groupDirs)
        fprintf('Warning: Group %d does not exist, skipping.\n', g);
        continue;
    end
    
    fprintf('Processing Group %d...\n', g);
    
    % 找到属于当前组的数据索引
    group_data_indices = [];
    for data_idx = 1:length(all_radiationData)
        if isKey(data_to_group_map, data_idx) && data_to_group_map(data_idx) == g
            group_data_indices(end+1) = data_idx;
        end
    end
    
    % 处理当前组的每个算例
    for data_idx = group_data_indices
        if data_idx > length(all_radiationData) || isempty(all_radiationData{data_idx})
            continue;
        end
        
        radInfo = all_radiationData{data_idx};
        total_cases_exported = total_cases_exported + 1;
        
        % 基本信息
        export_data.Directory{end+1} = radInfo.dirName;
        
        % 从radInfo中提取已计算的数据（这些在主脚本中已经计算并存储）
        if isfield(radInfo, 'totrad')
            export_data.Prad_total(end+1) = radInfo.totrad;
        else
            export_data.Prad_total(end+1) = NaN;
        end
        
        % 计算芯部平均Zeff（参考主脚本方法）
        if isfield(radInfo, 'Zeff') && ~isempty(radInfo.Zeff)
            core_indices = 25:72; % 对应主脚本中的core_indices_trimmed
            [nrows, ncols] = size(radInfo.Zeff);
            valid_core_indices = core_indices(core_indices <= nrows);
            valid_cols = min(12, ncols);
            
            if ~isempty(valid_core_indices) && valid_cols > 0
                Zeff_core_region = radInfo.Zeff(valid_core_indices, 1:valid_cols);
                averageZeff_core = mean(Zeff_core_region(:), 'omitnan');
            else
                averageZeff_core = NaN;
            end
        else
            averageZeff_core = NaN;
        end
        export_data.AverageZeff_core(end+1) = averageZeff_core;
        
        % 计算芯部平均电子密度
        if isfield(radInfo, 'plasma') && isfield(radInfo.plasma, 'ne') && ~isempty(radInfo.plasma.ne)
            ne_data = radInfo.plasma.ne(2:end-1, 2:end-1); % 去边界
            [nrows, ncols] = size(ne_data);
            core_indices = 25:72;
            valid_core_indices = core_indices(core_indices <= nrows);
            valid_cols = min(12, ncols);
            
            if ~isempty(valid_core_indices) && valid_cols > 0
                ne_core_region = ne_data(valid_core_indices, 1:valid_cols);
                ne_core_average = mean(ne_core_region(:), 'omitnan');
                ne2_core = mean(ne_core_region(:).^2, 'omitnan');
            else
                ne_core_average = NaN;
                ne2_core = NaN;
            end
        else
            ne_core_average = NaN;
            ne2_core = NaN;
        end
        export_data.Average_ne_core(end+1) = ne_core_average;
        export_data.Ne2_core(end+1) = ne2_core;
        
        % 计算极向平均D+密度
        if isfield(radInfo, 'plasma') && isfield(radInfo.plasma, 'na') && ~isempty(radInfo.plasma.na)
            na_data = radInfo.plasma.na(2:end-1, 2:end-1, :); % 去边界
            if size(na_data, 3) >= 2
                nD_plus_data = na_data(:, :, 2); % D+密度
                average_nD_plus_poloidal = mean(nD_plus_data(:), 'omitnan');
            else
                average_nD_plus_poloidal = NaN;
            end
        else
            average_nD_plus_poloidal = NaN;
        end
        export_data.Average_nD_plus_poloidal(end+1) = average_nD_plus_poloidal;
        
        % 计算平均Ne离子带电密度
        if isfield(radInfo, 'plasma') && isfield(radInfo.plasma, 'na') && ~isempty(radInfo.plasma.na)
            na_data = radInfo.plasma.na(2:end-1, 2:end-1, :); % 去边界
            if size(na_data, 3) >= 12
                Ne_ion_data = na_data(:, :, 3:12); % Ne离子密度 (Ne1+ to Ne10+)
                charge_weighted_density = zeros(size(Ne_ion_data, 1), size(Ne_ion_data, 2));
                for charge = 1:10
                    if size(Ne_ion_data, 3) >= charge
                        charge_weighted_density = charge_weighted_density + charge * Ne_ion_data(:, :, charge);
                    end
                end
                average_Ne_ion_charge_density = mean(charge_weighted_density(:), 'omitnan');
            else
                average_Ne_ion_charge_density = NaN;
            end
        else
            average_Ne_ion_charge_density = NaN;
        end
        export_data.Average_Ne_ion_charge_density_core(end+1) = average_Ne_ion_charge_density;
        
        % 功率相关参数（这些需要从主脚本的计算结果中获取，这里设为NaN）
        % 在实际使用中，这些值应该从主脚本的全局变量中获取
        export_data.Ptot(end+1) = NaN; % 需要从主脚本获取total_Pinput
        export_data.Prad_vs_Ptot(end+1) = NaN; % 需要从主脚本获取Prad_frac_Ptot
        export_data.Prad_over_ZeffMinus1(end+1) = export_data.Prad_total(end) / max(averageZeff_core - 1, eps);
        export_data.Prad_over_Pin_ZeffMinus1(end+1) = NaN; % 需要从主脚本获取
        export_data.fna_core_D_plus(end+1) = NaN; % 需要从主脚本获取sum_fna_results
        
        % 辐射组分（从radInfo中获取）
        if isfield(radInfo, 'ratio_D')
            export_data.Ratio_D(end+1) = radInfo.ratio_D;
        else
            export_data.Ratio_D(end+1) = NaN;
        end
        
        if isfield(radInfo, 'ratio_Ne')
            export_data.Ratio_imp(end+1) = radInfo.ratio_Ne;
        else
            export_data.Ratio_imp(end+1) = NaN;
        end
        
        if isfield(radInfo, 'div_fraction')
            export_data.Div_fraction(end+1) = radInfo.div_fraction;
        else
            export_data.Div_fraction(end+1) = NaN;
        end
        
        % 芯部和主SOL辐射功率
        if isfield(radInfo, 'totrad_ns') && isfield(radInfo, 'volcell') && ...
           ~isempty(radInfo.totrad_ns) && ~isempty(radInfo.volcell)
            
            [nrows_rad, ncols_rad] = size(radInfo.totrad_ns);
            [nrows_vol, ncols_vol] = size(radInfo.volcell);
            
            if nrows_rad == nrows_vol && ncols_rad == ncols_vol
                core_indices = 25:72;
                valid_core_indices = core_indices(core_indices <= nrows_rad);
                
                % 芯部辐射功率
                if ~isempty(valid_core_indices) && ncols_rad >= 12
                    totrad_core = sum(sum(radInfo.totrad_ns(valid_core_indices, 1:12) .* ...
                                         radInfo.volcell(valid_core_indices, 1:12))) * 1e-6;
                else
                    totrad_core = NaN;
                end
                
                % 主SOL辐射功率
                if ~isempty(valid_core_indices) && ncols_rad >= 13
                    totrad_main_SOL = sum(sum(radInfo.totrad_ns(valid_core_indices, 13:end) .* ...
                                             radInfo.volcell(valid_core_indices, 13:end))) * 1e-6;
                else
                    totrad_main_SOL = NaN;
                end
            else
                totrad_core = NaN;
                totrad_main_SOL = NaN;
            end
        else
            totrad_core = NaN;
            totrad_main_SOL = NaN;
        end
        export_data.Prad_core(end+1) = totrad_core;
        export_data.Prad_main_SOL(end+1) = totrad_main_SOL;
        
        % Zeff组分（需要详细计算，这里设为NaN）
        export_data.AverageZeff_D_core(end+1) = NaN; % 需要详细计算
        export_data.AverageZeff_Ne_core(end+1) = NaN; % 需要详细计算
    end
end

% 创建输出表格（完全按照主脚本的VariableNames）
if total_cases_exported > 0
    outputTable = table( ...
        export_data.Directory', ...
        export_data.Prad_total', ...
        export_data.AverageZeff_core', ...
        export_data.Average_ne_core', ...
        export_data.Ne2_core', ...
        export_data.Average_nD_plus_poloidal', ...
        export_data.Average_Ne_ion_charge_density_core', ...
        export_data.Ptot', ...
        export_data.Prad_vs_Ptot', ...
        export_data.Prad_over_ZeffMinus1', ...
        export_data.Prad_over_Pin_ZeffMinus1', ...
        export_data.fna_core_D_plus', ...
        export_data.Ratio_D', ...
        export_data.Ratio_imp', ...
        export_data.Div_fraction', ...
        export_data.Prad_core', ...
        export_data.Prad_main_SOL', ...
        export_data.AverageZeff_D_core', ...
        export_data.AverageZeff_Ne_core', ...
        'VariableNames', {'Directory', 'Prad_total', 'AverageZeff_core', 'Average_ne_core', ...
                          'Ne2_core', 'Average_nD_plus_poloidal', 'Average_Ne_ion_charge_density_core', ...
                          'Ptot', 'Prad_vs_Ptot', 'Prad_over_ZeffMinus1', 'Prad_over_Pin_ZeffMinus1', ...
                          'fna_core_D_plus', 'Ratio_D', 'Ratio_imp', 'Div_fraction', 'Prad_core', 'Prad_main_SOL', ...
                          'AverageZeff_D_core', 'AverageZeff_Ne_core'} ...
    );
    
    % 生成精确到秒的时间戳，避免文件重名覆盖
    currentDateTime = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    group_str = sprintf('groups_%s', strjoin(arrayfun(@num2str, selected_groups, 'UniformOutput', false), '_'));
    outputFileName = fullfile(pwd, sprintf('custom_export_%s_%s.csv', group_str, currentDateTime));

    % 检查文件是否已存在，如果存在则添加序号后缀
    counter = 1;
    originalFileName = outputFileName;
    while exist(outputFileName, 'file')
        [filepath, name, ext] = fileparts(originalFileName);
        outputFileName = fullfile(filepath, sprintf('%s_%d%s', name, counter, ext));
        counter = counter + 1;
    end

    % 保存CSV文件
    writetable(outputTable, outputFileName);
    
    fprintf('Custom CSV data exported to: %s\n', outputFileName);
    fprintf('Exported %d cases from %d groups.\n', total_cases_exported, length(selected_groups));
    fprintf('Selected groups: %s\n', mat2str(selected_groups));
    
    % 显示导出的组信息
    for g = selected_groups
        if g <= length(groupDirs)
            fprintf('Group %d: %d cases\n', g, length(groupDirs{g}));
        end
    end
else
    fprintf('No valid cases found in selected groups.\n');
end

end
