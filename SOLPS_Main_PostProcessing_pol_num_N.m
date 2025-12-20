% ========================================================================
% 说明：
%   服务器端使用matlab2017b。
%   这是处理充N（氮）杂质的SOLPS-ITER仿真数据的主脚本，基于充Ne主脚本修改。
%   保留了原脚本的所有前处理与拟合分析流程。
%   在后处理绘图阶段，改为调用拆分的绘图脚本。
%   另外，输出的 CSV 文件多增加了列 "Prad_over_ZeffMinus1"，
%   用于表征 Prad_total / (Zeff - 1) 的辐射效率。
%
%   新增功能：
%   - 支持灵活的预定义算例组选择（方法3）
%   - 可按BT方向+N浓度组合选择（如 fav N0.5, unfav N1.5）
%   - 可按BT方向+功率组合选择（如 fav 5.5MW, unfav 6MW）
%   - 完全向后兼容原有的3种选择方式
%
%   注意: 服务器端 MATLAB 命令行界面不支持中文显示。所有需要显示的文本都已翻译成英文。
%       中文注释保留，因为它们是供用户参考的。
% ========================================================================
clear;

% ------------------------------------------------------------------------
% 添加必要的函数路径（带路径存在性检查）
% ------------------------------------------------------------------------
solps_base_path = '/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/scripts/MatlabPostProcessing';
required_paths = {
    fullfile(solps_base_path, 'Calc');
    fullfile(solps_base_path, 'IO');
    fullfile(solps_base_path, 'Plotting');
    fullfile(solps_base_path, 'myscript_fromCFETRserver_2023.11.2')
};

fprintf('Checking and adding required paths...\n');
missing_critical_paths = false;
for i = 1:length(required_paths)
    if exist(required_paths{i}, 'dir')
        addpath(required_paths{i});
        fprintf('  Added: %s\n', required_paths{i});
    else
        warning('Required path not found: %s', required_paths{i});
        fprintf('  Warning: Path not found: %s\n', required_paths{i});
        missing_critical_paths = true;
    end
end

% 如果缺少关键路径，给出更明确的提示
if missing_critical_paths
    fprintf('\nWarning: Some required paths are missing. This may cause errors during execution.\n');
    fprintf('Please ensure all SOLPS-ITER paths are correctly configured.\n\n');
end

% 获取当前工作目录路径
currentPath = pwd;

% ============= 用户选择读取目录的方式（支持灵活组合选择） =============
fprintf('Please choose how to select directories:\n');
fprintf('1: Scan all subdirectories under the current directory\n');
fprintf('2: Provide one or multiple directory paths\n');
fprintf('3: Use advanced flexible case filtering (custom selection + grouping)\n');
fprintf('4: Use advanced flexible case filtering for RERUN cases (hard-coded predefined list)\n');
method_choice = input('Please enter 1, 2, 3, or 4: ');

while method_choice ~= 1 && method_choice ~= 2 && method_choice ~= 3 && method_choice ~= 4
    fprintf('Invalid input, please enter 1, 2, 3, or 4.\n');
    method_choice = input('Please enter 1, 2, 3, or 4: ');
end

% 根据用户选择的方式获取目录列表
if method_choice == 1
    % --- 方法1：扫描当前目录下子目录 ---
    folders = dir(currentPath);
    subfolders = folders([folders.isdir]);
    % 去除 '.' 和 '..' 以及隐藏目录（名字以 '.' 开头的）
    subfolders = subfolders(~ismember({subfolders.name}, {'.', '..'}));
    subfolders = subfolders(~startsWith({subfolders.name}, '.'));

    if isempty(subfolders)
        error('No subdirectories found in the current directory.');
    end

    fprintf('Subdirectories under the current directory:\n');
    for i = 1:length(subfolders)
        fprintf('%d: %s\n', i, subfolders(i).name);
    end

    % 让用户选择需要对比的子目录
    selected = input('Please enter the indices of the directories to compare (e.g., [1 3 5]): ');

    % 检查输入合法性
    while any(selected > length(subfolders)) || any(selected < 1) || ~isvector(selected) || any(mod(selected, 1) ~= 0)
        fprintf('Invalid indices, please re-enter.\n');
        selected = input('Please enter the indices of the directories to compare (e.g., [1 3 5]): ');
    end

    compareDirs = {subfolders(selected).name};
    % 注意，这里需要包成 cell of cell 的结构
    groupDirs = {cell(length(compareDirs), 1)};

    for k = 1:length(compareDirs)
        groupDirs{1}{k} = fullfile(currentPath, compareDirs{k});
    end

elseif method_choice == 2
    % --- 方法2：用户手动输入多个目录组路径 ---
    groupDirs = {};
    group_number = 1;
    while true
        fprintf('Please enter the directory paths for group %d (one per line).\n', group_number);
        fprintf('Press Enter on an empty line to finish the group.\n');
        fprintf('Type "exit" to stop adding groups and proceed with current data.\n');

        group = {};
        exit_requested = false;
        while true
            tline = input('', 's');
            if isempty(tline)
                break;
            elseif strcmpi(tline, 'exit')
                exit_requested = true;
                break;
            else
                group{end+1} = tline;
            end
        end

        % 如果用户请求退出
        if exit_requested
            if ~isempty(groupDirs)
                fprintf('Exiting directory input. Will proceed with %d group(s) already entered.\n', length(groupDirs));
                break;
            else
                fprintf('No groups have been entered yet. Cannot proceed without at least one group.\n');
                fprintf('Continuing with directory input...\n');
                continue;
            end
        end

        fprintf('Directories entered for group %d:\n', group_number);
        for i = 1:length(group)
            fprintf('%s\n', group{i});
        end

        confirm = input('Are these directories correct? (y/n): ', 's');
        while ~strcmpi(confirm, 'y') && ~strcmpi(confirm, 'n')
            confirm = input('Please enter y or n: ', 's');
        end

        if strcmpi(confirm, 'y')
            groupDirs{end+1} = group;
            another = input('Do you want to enter another group? (y/n): ', 's');
            while ~strcmpi(another, 'y') && ~strcmpi(another, 'n')
                another = input('Please enter y or n: ', 's');
            end
            if strcmpi(another, 'y')
                group_number = group_number + 1;
                continue;
            else
                break;
            end
        else
            % 如果当前组为空且用户选择n，提供退出选项
            if isempty(group) && ~isempty(groupDirs)
                exit_choice = input('Current group is empty. Do you want to exit and proceed with existing groups? (y/n): ', 's');
                while ~strcmpi(exit_choice, 'y') && ~strcmpi(exit_choice, 'n')
                    exit_choice = input('Please enter y or n: ', 's');
                end
                if strcmpi(exit_choice, 'y')
                    fprintf('Exiting directory input. Will proceed with %d group(s) already entered.\n', length(groupDirs));
                    break;
                end
            end
            fprintf('Please re-enter the directories for group %d.\n', group_number);
        end
    end

    if isempty(groupDirs)
        error('No directories were entered.');
    end

    % 清理并检查用户输入的目录有效性
    for g = 1:length(groupDirs)
        dirs = groupDirs{g};
        compareDirs = cell(size(dirs));
        for i = 1:length(dirs)
            dir_trimmed = strtrim(dirs{i});
            % 去掉可能包裹的引号
            dir_clean = regexprep(dir_trimmed, '^''|''$', '');
            % 去掉"/./"等无意义的中间路径
            dir_clean = regexprep(dir_clean, '/\./$', '');
            % 去掉路径末尾多余的'/'
            dir_clean = regexprep(dir_clean, '/+$', '');
            compareDirs{i} = dir_clean;
        end

        invalidDirs = {};
        for k = 1:length(compareDirs)
            if ~exist(compareDirs{k}, 'dir')
                invalidDirs{end+1} = compareDirs{k};
            end
        end

        if ~isempty(invalidDirs)
            fprintf('The following directories do not exist:\n');
            for i = 1:length(invalidDirs)
                fprintf('%s\n', invalidDirs{i});
            end
            error('Please check the directory paths and try again.');
        end

        groupDirs{g} = compareDirs;
    end

elseif method_choice == 3
    % --- 方法3：高级灵活算例筛选（自定义选择+分组） ---
    fprintf('========================================================================\n');
    fprintf('ADVANCED FLEXIBLE CASE FILTERING\n');
    fprintf('========================================================================\n');
    fprintf('This mode allows you to:\n');
    fprintf('1. Freely select values for each variable (single, combination, or all)\n');
    fprintf('2. Choose which variables to use as grouping criteria\n');
    fprintf('3. Get results grouped by your selected criteria\n');
    fprintf('========================================================================\n');

    % 调用新的灵活筛选函数
    groupDirs = advanced_flexible_filtering_N();

elseif method_choice == 4
    % --- 方法4：高级灵活算例筛选（重算算例专用，目录带_input后缀） ---
    fprintf('========================================================================\n');
    fprintf('ADVANCED FLEXIBLE CASE FILTERING - RERUN CASES (N)\n');
    fprintf('========================================================================\n');
    fprintf('This mode is specifically for rerun cases with _input suffixes.\n');
    fprintf('Rerun paths are loaded from a hard-coded predefined group file.\n');
    fprintf('Grouping and ordering follow mode 3 (original version).\n');
    fprintf('========================================================================\n');

    % 调用同一个筛选入口，但切换到rerun版本（内部使用硬编码的重算算例清单）
    groupDirs = advanced_flexible_filtering_N('rerun');

else
    error('Invalid selection method.');
end

num_groups = length(groupDirs);

% ------------------------------------------------------------------------
% 初始化需要收集的数据（供后续分析或绘图）
% 估算总目录数量用于预分配
% ------------------------------------------------------------------------
total_dirs_estimate = 0;
for g = 1:num_groups
    total_dirs_estimate = total_dirs_estimate + length(groupDirs{g});
end

% 预分配数组以提高性能
all_simplifiedDirNames_collected = cell(total_dirs_estimate, 1);
all_fullfileDirs_collected = cell(total_dirs_estimate, 1);
all_Prad_total_collected = zeros(total_dirs_estimate, 1);
all_averageZeff_core_collected = zeros(total_dirs_estimate, 1);
all_ne2_core_collected = zeros(total_dirs_estimate, 1);
all_ne_core_average_collected = zeros(total_dirs_estimate, 1);
all_average_nD_plus_poloidal_collected = zeros(total_dirs_estimate, 1);
all_average_N_ion_charge_density_collected = zeros(total_dirs_estimate, 1);
skippedDirs = cell(total_dirs_estimate, 1);  % 用于存储被跳过的目录
skipped_count = 0;  % 跳过目录计数器

% 新增加的收集数组（预分配）
all_ratio_D_collected = zeros(total_dirs_estimate, 1);    % D辐射占比
all_ratio_N_collected = zeros(total_dirs_estimate, 1);    % N辐射占比
all_div_fraction_collected = zeros(total_dirs_estimate, 1); % div区辐射占比
all_Prad_core_collected = zeros(total_dirs_estimate, 1); % 芯部辐射功率
all_Prad_main_SOL_collected = zeros(total_dirs_estimate, 1); % 主SOL辐射功率
all_averageZeff_D_core_collected = zeros(total_dirs_estimate, 1); % 新增: 芯部平均 Zeff_D
all_averageZeff_N_core_collected = zeros(total_dirs_estimate, 1); % 新增: 芯部平均 Zeff_N

all_Dplus_separatrix_collected = zeros(total_dirs_estimate, 1);
all_puffingAmounts_collected = zeros(total_dirs_estimate, 1);

% 新增：OMP分离面外第一个网格的数据
all_ne_OMP_sep_outer_collected = zeros(total_dirs_estimate, 1);      % 电子密度
all_nD_plus_OMP_sep_outer_collected = zeros(total_dirs_estimate, 1); % 主离子密度
all_nN_total_OMP_sep_outer_collected = zeros(total_dirs_estimate, 1); % 杂质离子密度总和
all_Te_OMP_sep_outer_collected = zeros(total_dirs_estimate, 1);      % 电子温度

% 新增：OMP分离面上的电子密度（通过插值计算）
all_ne_OMP_separatrix_collected = zeros(total_dirs_estimate, 1);     % 分离面上电子密度

all_Ptot_collected = zeros(total_dirs_estimate, 1);
all_Prad_vs_Ptot = zeros(total_dirs_estimate, 1);

all_fna_core_D_plus = zeros(total_dirs_estimate, 1);

% 用于存储每个算例的辐射分布数据
all_radiationData = cell(total_dirs_estimate, 1);

% 用于存储时间戳检查结果
timestamp_check_results = cell(total_dirs_estimate, 1);
timestamp_check_status = false(total_dirs_estimate, 1);  % true表示通过检查，false表示未通过

% 用于存储b2fplasma文件状态
b2fplasma_status_results = cell(total_dirs_estimate, 1);
b2fplasma_file_exists = false(total_dirs_estimate, 1);  % true表示文件存在，false表示不存在

% 全局索引计数器
global_index = 0;

% 用于跟踪已处理的目录，避免重复处理
processed_dirs = {};  % 存储已处理的目录路径

% ------------------------------------------------------------------------
% 定义外中平面和分离面网格索引（请根据实际情况修正）
% ------------------------------------------------------------------------
outer_midplane_j_gmtry = 42;  % 外中平面网格索引
radial_index_14_gmtry = 14;   % 径向网格索引 14
radial_index_13_gmtry = 13;   % 径向网格索引 13, 分离面位于 13 和 14 之间

% ========================== 主数据处理循环 ==========================
for g = 1:num_groups
    fullCompareDirs = groupDirs{g};

    % 初始化当前组的收集变量 (修改点: 初始化为空数组)
    group_Prad_total = [];
    group_averageZeff_core = [];
    group_ne_core_average = [];
    group_ne2_core = [];
    group_average_nD_plus_poloidal = [];
    group_average_N_ion_charge_density = [];
    group_Ptot = [];
    group_Prad_vs_Ptot = [];
    group_fullfileDirs = {};
    group_averageZeff_D_core = []; % 新增: 组的芯部平均 Zeff_D
    group_averageZeff_N_core = []; % 新增: 组的芯部平均 Zeff_N

    % 新增组变量
    group_ratio_D = [];       % D辐射占比
    group_ratio_N = [];       % N辐射占比
    group_div_fraction = [];  % div区辐射占比
    group_Prad_core = [];     % 芯部辐射功率
    group_Prad_main_SOL = []; % 主SOL辐射功率
    group_fna_core_D_plus = []; % 芯部D+通量
    group_ne_OMP_separatrix = []; % 新增: OMP分离面上电子密度

    sum_fna_results = zeros(length(fullCompareDirs), 1);
    simplifiedDirNames = cell(length(fullCompareDirs), 1);
    numProcessedDirs = 0; % 记录已处理目录的数量

    averageZeff_core = zeros(length(fullCompareDirs), 1);
    Prad_total = zeros(length(fullCompareDirs), 1);
    ne2_core = zeros(length(fullCompareDirs), 1);
    ne_core_average = zeros(length(fullCompareDirs), 1);
    average_nD_plus_poloidal = zeros(length(fullCompareDirs), 1);
    average_N_ion_charge_density = zeros(length(fullCompareDirs), 1);

    total_Pinput = zeros(length(fullCompareDirs), 1);
    Prad_frac_Ptot = zeros(length(fullCompareDirs), 1);

    % 新增预分配数组
    Prad_core = zeros(length(fullCompareDirs), 1);
    Prad_main_SOL = zeros(length(fullCompareDirs), 1);

    for k = 1:length(fullCompareDirs)
        currentDir = fullCompareDirs{k};

        % ----------------------------------------------------------------
        % 检查是否已经处理过该目录，避免重复处理
        % ----------------------------------------------------------------
        if any(strcmp(processed_dirs, currentDir))
            fprintf('Directory already processed, skipping: %s\n', currentDir);
            continue;  % 跳过已处理的目录
        end

        outputFolderName = 'output';
        outputDir = fullfile(currentDir, outputFolderName);

        % 若 output 目录不存在，则创建
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
            fprintf('Folder %s does not exist, created.\n', outputDir);
        else
            fprintf('Folder %s already exists.\n', outputDir);
        end

        parentDir = fileparts(currentDir); % 获取父目录
        grandparentDir = fileparts(parentDir); % 获取祖父目录

        % ----------------------------------------------------------------
        % 寻找 structure.dat 文件(可能在若干层目录)
        % ----------------------------------------------------------------
        possible_structure_files = {
            fullfile(parentDir, 'baserun', 'structure.dat');
            fullfile(grandparentDir, 'baserun', 'structure.dat');
            fullfile(currentDir, 'structure.dat');
            fullfile(parentDir, 'structure.dat');
            fullfile(grandparentDir, 'structure.dat')
        };

        structure_file = '';
        for s_ = 1:length(possible_structure_files)
            if exist(possible_structure_files{s_}, 'file')
                structure_file = possible_structure_files{s_};
                fprintf('Found structure.dat at %s\n', structure_file);
                break;
            end
        end

        if isempty(structure_file)
            fprintf('Warning: structure.dat not found. Skipping this directory.\n');
            skipped_count = skipped_count + 1;
            skippedDirs{skipped_count} = currentDir; % 记录被跳过的目录
            continue;
        end

        % ----------------------------------------------------------------
        % 寻找关键文件(可能在若干层目录)，类似structure.dat的查找逻辑
        % ----------------------------------------------------------------

        % 定义需要查找的关键文件
        key_file_names = {'b2fgmtry', 'fort.44', 'b2fstate', 'b2fplasmf'};
        found_files = containers.Map();

        for file_idx = 1:length(key_file_names)
            file_name = key_file_names{file_idx};

            % 定义可能的文件位置（按优先级排序）
            possible_file_locations = {
                fullfile(currentDir, file_name);                    % 当前目录
                fullfile(parentDir, file_name);                     % 父目录
                fullfile(grandparentDir, file_name);                % 祖父目录
                fullfile(parentDir, 'baserun', file_name);          % 父目录的baserun子目录
                fullfile(grandparentDir, 'baserun', file_name)      % 祖父目录的baserun子目录
            };

            file_found = false;
            for loc_idx = 1:length(possible_file_locations)
                if exist(possible_file_locations{loc_idx}, 'file')
                    found_files(file_name) = possible_file_locations{loc_idx};
                    fprintf('Found %s at %s\n', file_name, possible_file_locations{loc_idx});
                    file_found = true;
                    break;
                end
            end

            if ~file_found
                fprintf('Warning: %s not found in any expected location for %s\n', file_name, currentDir);
                found_files(file_name) = '';  % 标记为未找到
            end
        end

        % 检查是否所有关键文件都找到了
        missing_files = {};
        for file_idx = 1:length(key_file_names)
            file_name = key_file_names{file_idx};
            if isempty(found_files(file_name))
                missing_files{end+1} = file_name;
            end
        end

        if ~isempty(missing_files)
            fprintf('Warning: Missing key file(s) in %s: %s, skipping.\n', currentDir, strjoin(missing_files, ', '));

            % ----------------------------------------------------------------
            % 生成详细的错误诊断信息并保存到文件
            % ----------------------------------------------------------------
            write_detailed_error_info(currentDir, missing_files, found_files, key_file_names);

            skipped_count = skipped_count + 1;
            skippedDirs{skipped_count} = currentDir; % 记录被跳过的目录
            continue;
        end

        % 获取找到的文件路径
        gmtry_file      = found_files('b2fgmtry');
        fort44_file     = found_files('fort.44');
        b2fstate_file   = found_files('b2fstate');
        b2fplasmf_file  = found_files('b2fplasmf');

        % ----------------------------------------------------------------
        % 检查 b2fplasmf 和 b2fplasma 文件的时间戳
        % ----------------------------------------------------------------
        timestamp_check_passed = true;
        timestamp_message = '';

        % 查找 b2fplasma 文件（多层目录查找）
        b2fplasma_file = '';
        possible_b2fplasma_locations = {
            fullfile(currentDir, 'b2fplasma');
            fullfile(parentDir, 'b2fplasma');
            fullfile(grandparentDir, 'b2fplasma');
            fullfile(parentDir, 'baserun', 'b2fplasma');
            fullfile(grandparentDir, 'baserun', 'b2fplasma')
        };

        for loc_idx = 1:length(possible_b2fplasma_locations)
            if exist(possible_b2fplasma_locations{loc_idx}, 'file')
                b2fplasma_file = possible_b2fplasma_locations{loc_idx};
                fprintf('Found b2fplasma at %s\n', b2fplasma_file);
                break;
            end
        end

        if ~isempty(b2fplasma_file)
            % 获取两个文件的信息
            b2fplasmf_info = dir(b2fplasmf_file);
            b2fplasma_info = dir(b2fplasma_file);

            % 比较时间戳
            if b2fplasmf_info.datenum <= b2fplasma_info.datenum
                timestamp_check_passed = false;
                timestamp_message = sprintf('WARNING: b2fplasmf (%s) is NOT newer than b2fplasma (%s)', ...
                    b2fplasmf_info.date, b2fplasma_info.date);
            else
                timestamp_message = sprintf('OK: b2fplasmf (%s) is newer than b2fplasma (%s)', ...
                    b2fplasmf_info.date, b2fplasma_info.date);
            end

            % 记录b2fplasma文件存在
            b2fplasma_exists = true;
            b2fplasma_status_message = sprintf('b2fplasma file found at: %s', b2fplasma_file);
        else
            timestamp_message = sprintf('INFO: b2fplasma file not found in any expected location for %s, skipping timestamp check', currentDir);
            % 如果b2fplasma文件不存在，我们认为检查通过（因为只有b2fplasmf文件）
            timestamp_check_passed = true;
            fprintf('Note: b2fplasma file not found in any expected location for %s. This may indicate the simulation is still running or incomplete.\n', currentDir);
            fprintf('Searched locations:\n');
            for loc_idx = 1:length(possible_b2fplasma_locations)
                fprintf('  - %s\n', possible_b2fplasma_locations{loc_idx});
            end

            % 记录b2fplasma文件不存在
            b2fplasma_exists = false;
            searched_locations_str = strjoin(possible_b2fplasma_locations, '; ');
            b2fplasma_status_message = sprintf('b2fplasma file NOT FOUND in any expected location for %s. Searched: %s. This may indicate the simulation is still running or incomplete.', currentDir, searched_locations_str);
        end

        fprintf('Timestamp check for %s: %s\n', currentDir, timestamp_message);

        % ----------------------------------------------------------------
        % 读取 puffingAmount (从 b2.neutrals.parameters 文件)
        % ----------------------------------------------------------------
        neutrals_file = fullfile(currentDir, 'b2.neutrals.parameters');
        if ~exist(neutrals_file, 'file')
            fprintf('Warning: %s not found, cannot get puffing amount.\n', neutrals_file);
            puffingAmount = NaN; % 如果文件不存在, 设置为 NaN
        else
            neutralsText = fileread(neutrals_file);
            neutralsLines = strsplit(neutralsText, '\n');
            neutralsTargetLine = '';
            % 找到包含 'userfluxparm(1,1)=' 的行
            for iLine = 1:length(neutralsLines)
                if contains(neutralsLines{iLine}, 'userfluxparm(1,1)=')
                    neutralsTargetLine = neutralsLines{iLine};
                    break;
                end
            end
            if ~isempty(neutralsTargetLine)
                neutralsNumbers = regexp(neutralsTargetLine, '=[^;]*', 'match');
                if ~isempty(neutralsNumbers)
                    neutralsNumStr = strrep(neutralsNumbers{1}(2:end), ';', '');
                    neutralsNumCells = strsplit(neutralsNumStr, ',');
                    neutralsNumCells = strtrim(neutralsNumCells); % 去除空格
                    if length(neutralsNumCells) >= 12
                        puffingAmountStr = neutralsNumCells{12};
                        puffingAmount = str2double(puffingAmountStr);
                        if ~isnan(puffingAmount)
                            puffingAmount = puffingAmount / 1e20; % 单位换算, 转换为 1e20
                        else
                            puffingAmount = NaN; % 如果转换失败, 设置为 NaN
                        end
                    else
                        puffingAmount = NaN; % 如果元素数量不足, 设置为 NaN
                    end
                else
                    puffingAmount = NaN; % 如果未找到数字, 设置为 NaN
                end
            else
                puffingAmount = NaN; % 如果未找到目标行, 设置为 NaN
            end
        end

        % ----------------------------------------------------------------
        % 尝试读取各类必要文件并进行数据处理
        % ----------------------------------------------------------------
        try
            structure   = read_structure(structure_file);
            gmtry       = read_b2fgmtry(gmtry_file);
            [neut, wld] = read_ft44(fort44_file);
            [nxd, nyd]  = size(gmtry.crx(:,:,1)); % 获取网格尺寸
            species_variables = 10; % D (2) + N (8)
            [gmtry1, plasma] = read_b2fplasmf(b2fplasmf_file, nxd-2, nyd-2, species_variables);

            % 验证关键数据结构
            if nxd ~= 98 || nyd ~= 28
                warning('Unexpected grid size in %s: %dx%d (expected 98x28)', currentDir, nxd, nyd);
            end

            % 验证plasma数据结构完整性
            required_fields = {'ne', 'te', 'ti', 'fna_mdf'};
            missing_fields = {};
            for field_idx = 1:length(required_fields)
                if ~isfield(plasma, required_fields{field_idx})
                    missing_fields{end+1} = required_fields{field_idx};
                end
            end
            if ~isempty(missing_fields)
                warning('Missing plasma fields in %s: %s', currentDir, strjoin(missing_fields, ', '));
            end

        catch ME
            fprintf('Error reading files in %s: %s\n', currentDir, ME.message);
            skipped_count = skipped_count + 1;
            skippedDirs{skipped_count} = currentDir; % 记录被跳过的目录
            continue;
        end

        % ================================================================
        % 定义芯部区域索引（根据不同网格尺寸使用不同索引）
        % ================================================================
        try
            % 原始网格（98*28）的芯部区域索引：用于直接从plasma结构体取得的变量
            core_indices_original = 26:73;   % 适用于98*28网格
            % 去除边界网格（96*26）的芯部区域索引：用于经过边界处理的变量
            core_indices_trimmed = 25:72;    % 适用于96*26网格（去掉边界网格后）

            % 验证索引范围的有效性（仅警告，不中断处理）
            if max(core_indices_original) > nxd || max(core_indices_trimmed) > (nxd-2)
                warning('Core indices may exceed grid dimensions in %s. Grid: %dx%d', currentDir, nxd, nyd);
                % 调整索引范围以适应当前网格
                core_indices_original = min(core_indices_original):min(max(core_indices_original), nxd);
                core_indices_trimmed = min(core_indices_trimmed):min(max(core_indices_trimmed), nxd-2);
            end

        % ================================================================
        % 获取 fna（流函数值）并做简单统计
        % 注意：fna_mdf直接来自plasma结构体，使用原始网格索引
        % ================================================================
        if isfield(plasma, 'fna_mdf')
            fna_mdf = plasma.fna_mdf;  % 这通常是单位面积通量(或密度)，具体视SOLPS定义而定
            sum_fna_core_D_plus = sum(fna_mdf(core_indices_original, 2, 2, 2)); % 对芯部 D+ 通量求和，使用原始网格索引
        else
            warning('fna data not found in plasma variable.');
            sum_fna_core_D_plus = NaN;
        end
        sum_fna_results(k) = sum_fna_core_D_plus;

        % 将温度从 J 转化为 eV (如果原始数据单位为J)
        J_to_eV = 1.602e-19;
        plasma.te_ev = plasma.te / J_to_eV;
        plasma.ti_ev = plasma.ti / J_to_eV;

        % ----------------------------------------------------------------
        % 各离子密度
        % nD(:,:,1) 为中性D，nD(:,:,2) 为带电D+。
        % nN(:,:,3:end) 表示N的各电离态（N0到N7+）。
        % ----------------------------------------------------------------
        nD = plasma.na(:,:,1:2);
        nN = plasma.na(:,:,3:end);  % 氮（N）

        % ============== 计算 Zeff ==============
        % D 带电态Z^2=1
        Zeff_D = nD(:,:,2)*1^2 ./ plasma.ne;

        % N的各带电态（i_Z = 1->N0, 2->N+, ..., 8->N7+）
        Zeff_N = zeros(nxd, nyd);
        for i_Z = 1:8
            charge_state = i_Z - 1;  % i_Z=1->0价, i_Z=2->1价, ..., i_Z=8->7价
            Zeff_N = Zeff_N + nN(:,:,i_Z)*(charge_state^2)./plasma.ne;
        end

        Zeff = Zeff_D + Zeff_N;
        % ================================================================
        % 注意：Zeff、plasma.ne、gmtry.vol都直接来自原始数据，使用原始网格索引
        % ================================================================
        core_Zeff = Zeff(core_indices_original, 2);  % 第二列才是芯部位置，使用原始网格索引
        core_ne = plasma.ne(core_indices_original, 2); % 获取芯部电子密度，使用原始网格索引

        % --- 计算芯部体积和 ---
        core_vol = gmtry.vol(core_indices_original, 2); % 获取对应网格的体积，使用原始网格索引
        core_vol_sum = sum(core_vol, 'omitnan'); % 计算总体积
        % --- 芯部体积和 计算结束 ---

        % 计算 ne * 体积 的和 (用于后续加权平均)
        ne_vol_sum = sum(core_ne .* core_vol, 'omitnan'); % 计算 ne * 体积 的和

        % --- 计算电子密度加权平均 Zeff_D ---
        core_Zeff_D = Zeff_D(core_indices_original, 2); % 提取芯部 Zeff_D，使用原始网格索引
        core_Zeff_N = Zeff_N(core_indices_original, 2); % 提取芯部 Zeff_N，使用原始网格索引

        if ne_vol_sum == 0 || isnan(ne_vol_sum)
            averageZeff_D_core = NaN;
            warning('Core electron count sum is zero or NaN, cannot calculate electron-density-weighted average Zeff_D.');
        else
            Zeff_D_ne_vol_sum = sum(core_Zeff_D .* core_ne .* core_vol, 'omitnan');
            averageZeff_D_core = Zeff_D_ne_vol_sum / ne_vol_sum; % 电子密度加权平均 Zeff_D
        end
        % --- 电子密度加权平均 Zeff_D 计算结束 ---

        % --- 计算电子密度加权平均 Zeff_N ---
        if ne_vol_sum == 0 || isnan(ne_vol_sum)
            averageZeff_N_core = NaN;
            warning('Core electron count sum is zero or NaN, cannot calculate electron-density-weighted average Zeff_N.');
        else
            Zeff_N_ne_vol_sum = sum(core_Zeff_N .* core_ne .* core_vol, 'omitnan');
            averageZeff_N_core = Zeff_N_ne_vol_sum / ne_vol_sum; % 电子密度加权平均 Zeff_N
        end
        % --- 电子密度加权平均 Zeff_N 计算结束 ---

        % --- 计算电子密度加权平均 Zeff ---
        Zeff_ne_vol_sum = sum(core_Zeff .* core_ne .* core_vol, 'omitnan'); % 计算 Zeff * ne * 体积 的和

        if ne_vol_sum == 0 || isnan(ne_vol_sum) % 添加除零保护
            averageZeff = NaN;
            warning('Core electron count sum is zero or NaN, cannot calculate electron-density-weighted average Zeff.');
        else
            averageZeff = Zeff_ne_vol_sum / ne_vol_sum; % 电子密度加权平均 Zeff
        end
        % --- 电子密度加权平均 Zeff 计算结束 ---

        averageZeff_core(k) = averageZeff;

        % ----------------------------------------------------------------
        % 准备辐射功率计算的数据
        % ----------------------------------------------------------------
        volcell = gmtry.vol(2:end-1,2:end-1); % 排除边界单元
        % 线辐射(含束缚线辐射,可见线辐射等)
        linrad_ns = abs(plasma.rqrad(2:end-1,2:end-1,:))./volcell;
        linrad_D  = sum(linrad_ns(:,:,1:2),3);       % D部分
        linrad_N = sum(linrad_ns(:,:,3:end),3);     % N部分

        % 韧致辐射
        brmrad_ns = abs(plasma.rqbrm(2:end-1,2:end-1,:))./volcell;
        brmrad_D  = sum(brmrad_ns(:,:,1:2),3);
        brmrad_N = sum(brmrad_ns(:,:,3:end),3);

        % 中性相关辐射
        neurad_D  = abs(neut.eneutrad(:,:,1))./volcell;   % 中性D辐射
        neurad_N = abs(neut.eneutrad(:,:,2))./volcell;   % 中性N辐射

        % 分子辐射、复合辐射等
        molrad_D = abs(neut.emolrad(:,:))./volcell;
        ionrad_D = abs(neut.eionrad(:,:))./volcell;

        % D 和 N 各自总辐射
        totrad_D  = linrad_D + brmrad_D + neurad_D + molrad_D + ionrad_D;
        totrad_N = linrad_N + brmrad_N + neurad_N;  % 氮（N）
        totrad_ns = totrad_D + totrad_N;  % 合计

        % 计算总辐射功率 (MW)
        totrad = sum(sum(totrad_ns.*volcell))*1e-6;
        Prad_total(k) = totrad;

        % ================================================================
        % 计算芯部和主SOL辐射功率 (MW)
        % 注意：totrad_ns和volcell都经过了边界处理，使用去边界网格索引
        % ================================================================
        totrad_core = sum(sum(totrad_ns(core_indices_trimmed,1:12).*volcell(core_indices_trimmed,1:12))) * 1e-6;
        Prad_core(k) = totrad_core;

        % 计算主SOL辐射功率 (MW)
        totrad_main_SOL = sum(sum(totrad_ns(core_indices_trimmed,13:end).*volcell(core_indices_trimmed,13:end))) * 1e-6;
        Prad_main_SOL(k) = totrad_main_SOL;

        % ================================================================
        % 核心区 ne^2 和 ne (使用体积加权平均)
        % 注意：core_ne已在前面使用原始网格索引定义
        % ================================================================
        % core_ne = plasma.ne(core_indices_original, 2); % 第二列才是芯部位置 (已提前定义，使用原始网格索引)

        if core_vol_sum == 0 || isnan(core_vol_sum) % 复用 Zeff 计算时的 core_vol_sum
            average_ne2 = NaN;
            average_ne = NaN;
            warning('Core volume sum is zero or NaN, cannot calculate volume-weighted average ne or ne^2.');
        else
            % 体积加权平均 ne^2
            ne2_vol_sum = sum((core_ne.^2) .* core_vol, 'omitnan');
            average_ne2 = ne2_vol_sum / core_vol_sum;
            % 体积加权平均 ne
            ne_vol_sum = sum(core_ne .* core_vol, 'omitnan');
            average_ne = ne_vol_sum / core_vol_sum;
        end
        ne2_core(k) = average_ne2;        % 存储体积加权平均 ne^2
        ne_core_average(k) = average_ne;  % 存储体积加权平均 ne

        % ================================================================
        % 极向平均 D+ 密度 (体积加权平均)
        % 注意：plasma.na和gmtry.vol都直接来自原始数据，使用原始网格索引
        % ================================================================
        nD_plus = plasma.na(:,:,2);
        core_nD_plus = nD_plus(core_indices_original, 2); % 第二列才是芯部位置，使用原始网格索引
        core_nD_plus_vol = core_nD_plus .* gmtry.vol(core_indices_original, 2); % 乘以体积，使用原始网格索引
        core_nD_plus_vol_sum = sum(core_nD_plus_vol, 'omitnan'); % 芯部 D+ 密度乘以体积求和
        core_vol_sum_D_plus = sum(gmtry.vol(core_indices_original, 2), 'omitnan'); % 芯部体积求和（重新计算避免混淆）
        average_nD_plus_poloidal_calc = core_nD_plus_vol_sum / core_vol_sum_D_plus; % 极向平均 D+ 密度
        average_nD_plus_poloidal(k) = average_nD_plus_poloidal_calc;

        % ================================================================
        % 平均N离子带电密度 (使用体积加权平均)
        % 注意：nN直接来自plasma数据，使用原始网格索引
        % ================================================================
        total_N_ion_charge_density = zeros(nxd, nyd);
        for i_Z = 1:8
            charge_state = i_Z - 1;
            total_N_ion_charge_density = total_N_ion_charge_density + nN(:,:,i_Z)*charge_state;
        end
        core_total_N_ion_charge_density = total_N_ion_charge_density(core_indices_original, 2); % 第二列才是芯部位置，使用原始网格索引

        if core_vol_sum == 0 || isnan(core_vol_sum) % 复用 Zeff 计算时的 core_vol_sum
            average_total_N_ion_charge_density_core = NaN;
            warning('Core volume sum is zero or NaN, cannot calculate volume-weighted N ion charge density.');
        else
            % 体积加权平均 N 离子电荷密度
            n_ion_charge_density_vol_sum = sum(core_total_N_ion_charge_density .* core_vol, 'omitnan');
            average_total_N_ion_charge_density_core = n_ion_charge_density_vol_sum / core_vol_sum;
        end
        average_N_ion_charge_density(k) = average_total_N_ion_charge_density_core; % 存储体积加权平均值

        % ----------------------------------------------------------------
        % 外中平面分离面处 D+ 密度（修正后，分离面位于径向 13 和 14 网格之间）
        % 采用两点插值以获取分离面处的 D+ 密度
        % ----------------------------------------------------------------
        x13c = (gmtry.hy(outer_midplane_j_gmtry, radial_index_13_gmtry))/2; % 13号网格右边界
        x14c = gmtry.hy(outer_midplane_j_gmtry, radial_index_13_gmtry) + ...
               (gmtry.hy(outer_midplane_j_gmtry, radial_index_14_gmtry))/2;   % 14号网格左边界
        nD_plus_13 = plasma.na(outer_midplane_j_gmtry, radial_index_13_gmtry, 2); % 13号网格 D+ 密度
        nD_plus_14 = plasma.na(outer_midplane_j_gmtry, radial_index_14_gmtry, 2); % 14号网格 D+ 密度
        xQuery = gmtry.hy(outer_midplane_j_gmtry, radial_index_14_gmtry); % 13号网格右边界位置（即我们关心的位置）
        nD_plus_separatrix = interp1([x13c, x14c], [nD_plus_13, nD_plus_14], xQuery, 'linear'); % 线性插值

        % ----------------------------------------------------------------
        % 外中平面分离面处电子密度（采用相同的插值方法）
        % ----------------------------------------------------------------
        ne_13 = plasma.ne(outer_midplane_j_gmtry, radial_index_13_gmtry); % 13号网格电子密度
        ne_14 = plasma.ne(outer_midplane_j_gmtry, radial_index_14_gmtry); % 14号网格电子密度
        ne_OMP_separatrix = interp1([x13c, x14c], [ne_13, ne_14], xQuery, 'linear'); % 线性插值

        % ----------------------------------------------------------------
        % 新增：OMP分离面外第一个网格的数据（径向网格14）
        % ----------------------------------------------------------------
        % 电子密度
        ne_OMP_sep_outer = plasma.ne(outer_midplane_j_gmtry, radial_index_14_gmtry);

        % 主离子密度（D+）
        nD_plus_OMP_sep_outer = plasma.na(outer_midplane_j_gmtry, radial_index_14_gmtry, 2);

        % 杂质离子密度总和（N各离子价态加和，排除中性N0）
        nN_total_OMP_sep_outer = sum(plasma.na(outer_midplane_j_gmtry, radial_index_14_gmtry, 4:10));

        % 电子温度（eV）
        Te_OMP_sep_outer = plasma.te_ev(outer_midplane_j_gmtry, radial_index_14_gmtry);

        % 生成一个便于显示的简化目录名
        simplifiedDirName = generate_simplified_dir_name(currentDir);

        numProcessedDirs = numProcessedDirs + 1;

        % ================================================================
        % 计算总输入功率 Ptot (简化示例)，并计算 Prad / Ptot
        % 注意：plasma.fhe_mdf和plasma.fhi_mdf直接来自plasma数据，使用原始网格索引
        % ================================================================
        if isfield(plasma, 'fhe_mdf') && isfield(plasma, 'fhi_mdf')
            Ptot = sum(plasma.fhe_mdf(core_indices_original,2,2) + plasma.fhi_mdf(core_indices_original,2,2), 'omitnan');
        else
            Ptot = NaN;
        end
        total_Pinput(k) = Ptot / 1e6; % 转为 MW
        frac_Prad_Ptot = Prad_total(k) / total_Pinput(k);
        Prad_frac_Ptot(k) = frac_Prad_Ptot;

        % ================================================================
        % 收集辐射分布信息，以便后续调用外部脚本绘图
        % 注意：这里的计算都基于经过边界处理的数据，使用去边界网格索引
        % ================================================================
        if isfield(gmtry,'leftcut') && isfield(gmtry,'rightcut')
            index_div = [1:gmtry.leftcut, gmtry.rightcut+1 : (nxd-2)]; % 1-24，外偏滤器区域；73-96，内偏滤器区域；这里对应的是裁剪为96*26的网格
         else
             index_div = [];
         end

         totrad_div = 0;
         if ~isempty(index_div)
             totrad_div = sum(sum(totrad_ns(index_div,:).*volcell(index_div,:))) * 1e-6; % div区辐射，使用去边界网格数据
         end

         totrad_core_for_radInfo = sum(sum(totrad_ns(core_indices_trimmed,1:12).*volcell(core_indices_trimmed,1:12))) * 1e-6; % 芯部辐射，使用去边界网格索引

         ratio_D  = sum(sum(totrad_D)) / sum(sum(totrad_ns));   % D的辐射占比
         ratio_N = sum(sum(totrad_N)) / sum(sum(totrad_ns));  % N的辐射占比

         radInfo = struct(); % 创建结构体存储辐射信息
         radInfo.linrad_ns   = linrad_ns; % 线辐射
         radInfo.brmrad_ns   = brmrad_ns; % 韧致辐射
         radInfo.gmtry       = gmtry;     % 几何信息
         radInfo.structure   = structure; % 结构信息
         radInfo.plasma      = plasma;    % 等离子体参数
         radInfo.neut        = neut;      % 中性粒子参数
         radInfo.totrad_ns   = totrad_ns; % 总辐射 (功率密度)
         radInfo.totrad_D    = totrad_D;  % D 总辐射
         radInfo.totrad_N    = totrad_N;  % N 总辐射
         radInfo.linrad_D    = linrad_D;  % D 线辐射
         radInfo.linrad_N    = linrad_N;  % N 线辐射
         radInfo.brmrad_D    = brmrad_D;  % D 韧致辐射
         radInfo.brmrad_N    = brmrad_N;  % N 韧致辐射
         radInfo.neurad_D    = neurad_D;  % D 中性辐射
         radInfo.neurad_N    = neurad_N;  % N 中性辐射
         radInfo.molrad_D    = molrad_D;  % D 分子辐射
         radInfo.ionrad_D    = ionrad_D;  % D 复合辐射
         radInfo.Zeff        = Zeff;      % Zeff 分布
         radInfo.volcell     = volcell;   % 网格体积
         radInfo.dirName     = currentDir; % 目录名
         radInfo.totrad      = totrad;     % 总辐射功率 (MW)
         radInfo.totrad_div  = totrad_div; % div区辐射功率 (MW)
         radInfo.ratio_D     = ratio_D;    % D 辐射占比
         radInfo.ratio_N     = ratio_N;    % N 辐射占比
         if totrad > 0
             radInfo.div_fraction = totrad_div / totrad; % div 区辐射占比
         else
             radInfo.div_fraction = NaN; % 如果总辐射为 0, 则设置为 NaN
         end

        % ----------------------------------------------------------------
        % 收集各算例的关键信息 (使用索引而非动态扩展)
        % ----------------------------------------------------------------
        global_index = global_index + 1;
        all_simplifiedDirNames_collected{global_index} = simplifiedDirName;  % 简化目录名
        all_fullfileDirs_collected{global_index} = currentDir;       % 完整目录路径
        all_Prad_total_collected(global_index) = Prad_total(k);      % 总辐射功率
        all_averageZeff_core_collected(global_index) = averageZeff_core(k);  % 芯部平均 Zeff
        all_ne2_core_collected(global_index) = ne2_core(k);        % 芯部平均 ne^2
        all_ne_core_average_collected(global_index) = ne_core_average(k);   % 芯部平均 ne
        all_average_nD_plus_poloidal_collected(global_index) = average_nD_plus_poloidal(k); % 极向平均 D+ 密度
        all_average_N_ion_charge_density_collected(global_index) = average_N_ion_charge_density(k); % 平均 N 离子带电密度
        all_Ptot_collected(global_index) = total_Pinput(k);   % 总输入功率
        all_Prad_vs_Ptot(global_index) = Prad_frac_Ptot(k); % Prad / Ptot
        all_fna_core_D_plus(global_index) = sum_fna_results(k); % 芯部 D+ 通量
        all_averageZeff_D_core_collected(global_index) = averageZeff_D_core; % 新增: 芯部平均 Zeff_D
        all_averageZeff_N_core_collected(global_index) = averageZeff_N_core; % 新增: 芯部平均 Zeff_N
        all_Dplus_separatrix_collected(global_index) = nD_plus_separatrix;
        all_puffingAmounts_collected(global_index) = puffingAmount;

        % 新增：OMP分离面外第一个网格的密度数据收集
        all_ne_OMP_sep_outer_collected(global_index) = ne_OMP_sep_outer;
        all_nD_plus_OMP_sep_outer_collected(global_index) = nD_plus_OMP_sep_outer;
        all_nN_total_OMP_sep_outer_collected(global_index) = nN_total_OMP_sep_outer;
        all_Te_OMP_sep_outer_collected(global_index) = Te_OMP_sep_outer;

        % 新增：OMP分离面上电子密度数据收集
        all_ne_OMP_separatrix_collected(global_index) = ne_OMP_separatrix;

        % 新增数据收集
        all_ratio_D_collected(global_index) = ratio_D;       % D辐射占比
        all_ratio_N_collected(global_index) = ratio_N;       % N辐射占比
        all_div_fraction_collected(global_index) = radInfo.div_fraction;  % div区辐射占比
        all_Prad_core_collected(global_index) = Prad_core(k); % 芯部辐射功率
        all_Prad_main_SOL_collected(global_index) = Prad_main_SOL(k); % 主SOL辐射功率

        all_radiationData{global_index} = radInfo; % 将当前算例的辐射信息添加到列表中

        % 存储时间戳检查结果
        timestamp_check_results{global_index} = timestamp_message;
        timestamp_check_status(global_index) = timestamp_check_passed;

        % 存储b2fplasma文件状态
        b2fplasma_status_results{global_index} = b2fplasma_status_message;
        b2fplasma_file_exists(global_index) = b2fplasma_exists;

        % ----------------------------------------------------------------
        % 收集当前目录数据到组变量 (修改点: 使用数组追加)
        % ----------------------------------------------------------------
        group_Prad_total(end+1) = Prad_total(k);
        group_averageZeff_core(end+1) = averageZeff_core(k);
        group_ne_core_average(end+1) = ne_core_average(k);
        group_ne2_core(end+1) = ne2_core(k);
        group_average_nD_plus_poloidal(end+1) = average_nD_plus_poloidal(k);
        group_average_N_ion_charge_density(end+1) = average_N_ion_charge_density(k);
        group_Ptot(end+1) = total_Pinput(k);
        group_Prad_vs_Ptot(end+1) = Prad_frac_Ptot(k);
        group_fullfileDirs{end+1} = currentDir;

        % 新增组数据收集
        group_ratio_D(end+1) = ratio_D;       % D辐射占比
        group_ratio_N(end+1) = ratio_N;       % N辐射占比
        group_div_fraction(end+1) = radInfo.div_fraction;  % div区辐射占比
        group_Prad_core(end+1) = Prad_core(k); % 芯部辐射功率
        group_Prad_main_SOL(end+1) = Prad_main_SOL(k); % 主SOL辐射功率
        group_averageZeff_D_core(end+1) = averageZeff_D_core; % 新增: 组的芯部平均 Zeff_D
        group_averageZeff_N_core(end+1) = averageZeff_N_core; % 新增: 组的芯部平均 Zeff_N
        group_fna_core_D_plus(end+1) = sum_fna_results(k); % 芯部D+通量
        group_ne_OMP_separatrix(end+1) = ne_OMP_separatrix; % 新增: OMP分离面上电子密度

        % ----------------------------------------------------------------
        % 将当前目录添加到已处理列表，避免重复处理
        % ----------------------------------------------------------------
        processed_dirs{end+1} = currentDir;

        catch ME_processing
            fprintf('Error processing data in %s: %s\n', currentDir, ME_processing.message);
            fprintf('  Error occurred at line: %s\n', ME_processing.stack(1).name);
            skipped_count = skipped_count + 1;
            skippedDirs{skipped_count} = currentDir; % 记录被跳过的目录
            continue;
        end

    end % inner loop for each directory in group

    % 提示哪些目录被跳过
    if skipped_count > 0
        fprintf('\nThe following directories were skipped due to missing files or errors:\n');
        for i = 1:skipped_count
            fprintf('%s\n', skippedDirs{i});
        end
    else
        fprintf('\nNo directories were skipped.\n');
    end

    if numProcessedDirs == 0
        error('No directories were processed. Please check if necessary files exist.');
    end

    % （也可在此处对每个组进行单独的处理或绘图）


    % 计算辐射效率
    group_Prad_over_ZeffMinus1 = group_Prad_total ./ (group_averageZeff_core - 1);
    group_Prad_over_Pin_ZeffMinus1 = group_Prad_total ./ (group_Ptot .* (group_averageZeff_core - 1));

    % 创建表格并保存为CSV
    outputTable_group = table( ...
        group_fullfileDirs', ...
        group_Prad_total', ...
        group_averageZeff_core', ...
        group_ne_core_average', ...
        group_ne2_core', ...
        group_average_nD_plus_poloidal', ...
        group_average_N_ion_charge_density', ...
        group_Ptot', ...
        group_Prad_vs_Ptot', ...
        group_Prad_over_ZeffMinus1', ...
        group_Prad_over_Pin_ZeffMinus1', ...
        group_fna_core_D_plus', ...   % 新增: 芯部D+通量
        group_ratio_D', ...           % 新增: D辐射占比
        group_ratio_N', ...          % 新增: N辐射占比
        group_div_fraction', ...      % 新增: div区辐射占比
        group_Prad_core', ...         % 新增: 芯部辐射功率
        group_Prad_main_SOL', ...     % 新增: 主SOL辐射功率
        group_averageZeff_D_core', ... % 新增: 芯部平均 Zeff_D
        group_averageZeff_N_core', ... % 新增: 芯部平均 Zeff_N
        group_ne_OMP_separatrix', ... % 新增: OMP分离面上电子密度
        'VariableNames', {'Directory', 'Prad_total', 'AverageZeff_core', 'Average_ne_core', ...
        'Ne2_core', 'Average_nD_plus_poloidal', 'Average_N_ion_charge_density_core', ...
        'Ptot', 'Prad_vs_Ptot', 'Prad_over_ZeffMinus1', 'Prad_over_Pin_ZeffMinus1', ...
        'fna_core_D_plus', 'Ratio_D', 'Ratio_imp', 'Div_fraction', 'Prad_core', 'Prad_main_SOL', ...
        'AverageZeff_D_core', 'AverageZeff_N_core', 'ne_OMP_separatrix'} ... % 更新变量名称
    );


    % 生成精确到秒的时间戳，避免文件重名覆盖
    currentDateTime_group = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    outputFileName = fullfile(pwd, sprintf('output_results_group%d_%s.csv', g, currentDateTime_group));

    % 检查文件是否已存在，如果存在则添加序号后缀
    counter = 1;
    originalFileName = outputFileName;
    while exist(outputFileName, 'file')
        [filepath, name, ext] = fileparts(originalFileName);
        outputFileName = fullfile(filepath, sprintf('%s_%d%s', name, counter, ext));
        counter = counter + 1;
    end

    writetable(outputTable_group, outputFileName);
    fprintf('Group %d data exported to: %s\n', g, outputFileName);

end % outer loop for each group

% ========================================================================
% 最终，我们将收集到的数据导出到 CSV 文件。
% 在这里增加 "Prad_over_ZeffMinus1" 列，用于描述辐射效率。
% ========================================================================

% 截断预分配的数组到实际使用的大小
if global_index < total_dirs_estimate
    all_simplifiedDirNames_collected = all_simplifiedDirNames_collected(1:global_index);
    all_fullfileDirs_collected = all_fullfileDirs_collected(1:global_index);
    all_Prad_total_collected = all_Prad_total_collected(1:global_index);
    all_averageZeff_core_collected = all_averageZeff_core_collected(1:global_index);
    all_ne2_core_collected = all_ne2_core_collected(1:global_index);
    all_ne_core_average_collected = all_ne_core_average_collected(1:global_index);
    all_average_nD_plus_poloidal_collected = all_average_nD_plus_poloidal_collected(1:global_index);
    all_average_N_ion_charge_density_collected = all_average_N_ion_charge_density_collected(1:global_index);
    all_Ptot_collected = all_Ptot_collected(1:global_index);
    all_Prad_vs_Ptot = all_Prad_vs_Ptot(1:global_index);
    all_fna_core_D_plus = all_fna_core_D_plus(1:global_index);
    all_averageZeff_D_core_collected = all_averageZeff_D_core_collected(1:global_index);
    all_averageZeff_N_core_collected = all_averageZeff_N_core_collected(1:global_index);
    all_Dplus_separatrix_collected = all_Dplus_separatrix_collected(1:global_index);
    all_puffingAmounts_collected = all_puffingAmounts_collected(1:global_index);
    all_ratio_D_collected = all_ratio_D_collected(1:global_index);
    all_ratio_N_collected = all_ratio_N_collected(1:global_index);
    all_div_fraction_collected = all_div_fraction_collected(1:global_index);
    all_Prad_core_collected = all_Prad_core_collected(1:global_index);
    all_Prad_main_SOL_collected = all_Prad_main_SOL_collected(1:global_index);

    % 新增：OMP分离面外第一个网格的密度数据截取
    all_ne_OMP_sep_outer_collected = all_ne_OMP_sep_outer_collected(1:global_index);
    all_nD_plus_OMP_sep_outer_collected = all_nD_plus_OMP_sep_outer_collected(1:global_index);
    all_nN_total_OMP_sep_outer_collected = all_nN_total_OMP_sep_outer_collected(1:global_index);
    all_Te_OMP_sep_outer_collected = all_Te_OMP_sep_outer_collected(1:global_index);

    % 新增：OMP分离面上电子密度数据截取
    all_ne_OMP_separatrix_collected = all_ne_OMP_separatrix_collected(1:global_index);
    all_radiationData = all_radiationData(1:global_index);

    % 截取时间戳检查结果
    timestamp_check_results = timestamp_check_results(1:global_index);
    timestamp_check_status = timestamp_check_status(1:global_index);

    % 截取b2fplasma文件状态结果
    b2fplasma_status_results = b2fplasma_status_results(1:global_index);
    b2fplasma_file_exists = b2fplasma_file_exists(1:global_index);
end

% 截断跳过目录列表
if skipped_count < total_dirs_estimate
    skippedDirs = skippedDirs(1:skipped_count);
end

% 如果某些算例 Zeff == 1，除数为0，会导致Inf或NaN, 需要自行判断或后续处理
Prad_over_ZeffMinus1_collected = all_Prad_total_collected ./ (all_averageZeff_core_collected - 1);
Prad_over_Pin_ZeffMinus1_collected = all_Prad_total_collected ./ (all_Ptot_collected .* (all_averageZeff_core_collected - 1));


outputTable = table( ...
    all_fullfileDirs_collected,                  ... % 目录 (移除转置: 已经是正确的列向量)
    all_Prad_total_collected,                    ... % Prad_total
    all_averageZeff_core_collected,              ... % AverageZeff_core
    all_ne_core_average_collected,               ... % Average_ne_core
    all_ne2_core_collected,                      ... % Ne2_core (修复: 直接使用原数组，保持一致性)
    all_average_nD_plus_poloidal_collected,       ... % Average_nD_plus_poloidal
    all_average_N_ion_charge_density_collected,  ... % Average_N_ion_charge_density_core
    all_Ptot_collected,                           ... % Ptot
    all_Prad_vs_Ptot,                             ... % Prad_vs_Ptot
    Prad_over_ZeffMinus1_collected,              ... % Prad_over_ZeffMinus1
    Prad_over_Pin_ZeffMinus1_collected,          ... % Prad_over_Pin_ZeffMinus1
    all_fna_core_D_plus,                         ... % fna_core_D_plus
    all_ratio_D_collected,                        ... % 新增: D辐射占比
    all_ratio_N_collected,                       ... % 新增: N辐射占比
    all_div_fraction_collected,                   ... % 新增: div区辐射占比
    all_Prad_core_collected,                      ... % 新增: 芯部辐射功率
    all_Prad_main_SOL_collected,                  ... % 新增: 主SOL辐射功率
    all_averageZeff_D_core_collected,             ... % 新增: 芯部平均 Zeff_D
    all_averageZeff_N_core_collected,            ... % 新增: 芯部平均 Zeff_N
    all_ne_OMP_separatrix_collected,              ... % 新增: OMP分离面上电子密度
    all_ne_OMP_sep_outer_collected,               ... % 新增: OMP分离面外第一个网格电子密度
    all_nD_plus_OMP_sep_outer_collected,          ... % 新增: OMP分离面外第一个网格主离子密度
    all_nN_total_OMP_sep_outer_collected,        ... % 新增: OMP分离面外第一个网格杂质离子密度总和
    all_Te_OMP_sep_outer_collected,               ... % 新增: OMP分离面外第一个网格电子温度
    'VariableNames', {'Directory', 'Prad_total', 'AverageZeff_core', 'Average_ne_core', ...
                      'Ne2_core', 'Average_nD_plus_poloidal', 'Average_N_ion_charge_density_core', ...
                      'Ptot', 'Prad_vs_Ptot', 'Prad_over_ZeffMinus1', 'Prad_over_Pin_ZeffMinus1', ...
                      'fna_core_D_plus', 'Ratio_D', 'Ratio_imp', 'Div_fraction', 'Prad_core', 'Prad_main_SOL', ...
                      'AverageZeff_D_core', 'AverageZeff_N_core', 'ne_OMP_separatrix', 'ne_OMP_sep_outer', 'nD_plus_OMP_sep_outer', 'nN_total_OMP_sep_outer', 'Te_OMP_sep_outer'} ... % 更新变量名称
);

% 生成精确到秒的时间戳，避免文件重名覆盖
currentDateTime = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
outputFileName = fullfile(pwd, ['output_results_', currentDateTime, '.csv']);

% 检查文件是否已存在，如果存在则添加序号后缀
counter = 1;
originalFileName = outputFileName;
while exist(outputFileName, 'file')
    [filepath, name, ext] = fileparts(originalFileName);
    outputFileName = fullfile(filepath, sprintf('%s_%d%s', name, counter, ext));
    counter = counter + 1;
end

writetable(outputTable, outputFileName);

fprintf('Calibration data has been exported to: %s\n', outputFileName);

% ========================================================================
% 生成时间戳检查报告
% ========================================================================
fprintf('\n========================================================================\n');
fprintf('TIMESTAMP CHECK REPORT\n');
fprintf('========================================================================\n');

% 统计时间戳检查结果
total_cases = length(timestamp_check_status);
passed_cases = sum(timestamp_check_status);
failed_cases = total_cases - passed_cases;

fprintf('Total cases processed: %d\n', total_cases);
fprintf('Cases with correct timestamp order (b2fplasmf newer than b2fplasma): %d\n', passed_cases);
fprintf('Cases with incorrect timestamp order: %d\n', failed_cases);

if failed_cases > 0
    fprintf('\nCases with timestamp issues:\n');
    fprintf('%-60s | %s\n', 'Directory', 'Timestamp Check Result');
    fprintf('%s\n', repmat('-', 1, 120));
    for i = 1:total_cases
        if ~timestamp_check_status(i)
            fprintf('%-60s | %s\n', all_fullfileDirs_collected{i}, timestamp_check_results{i});
        end
    end
end

% 生成时间戳检查报告文件
timestamp_report_filename = fullfile(pwd, ['timestamp_check_report_', currentDateTime, '.txt']);
counter = 1;
original_timestamp_filename = timestamp_report_filename;
while exist(timestamp_report_filename, 'file')
    [filepath, name, ext] = fileparts(original_timestamp_filename);
    timestamp_report_filename = fullfile(filepath, sprintf('%s_%d%s', name, counter, ext));
    counter = counter + 1;
end

% 写入时间戳检查报告文件
fid = fopen(timestamp_report_filename, 'w');
if fid ~= -1
    fprintf(fid, 'SOLPS File Timestamp Check Report\n');
    fprintf(fid, 'Generated on: %s\n\n', char(datetime('now')));
    fprintf(fid, 'Total cases processed: %d\n', total_cases);
    fprintf(fid, 'Cases with correct timestamp order (b2fplasmf newer than b2fplasma): %d\n', passed_cases);
    fprintf(fid, 'Cases with incorrect timestamp order: %d\n\n', failed_cases);

    fprintf(fid, 'Detailed Results:\n');
    fprintf(fid, '%s\n', repmat('=', 1, 120));
    for i = 1:total_cases
        status_str = '';
        if timestamp_check_status(i)
            status_str = '[PASS]';
        else
            status_str = '[FAIL]';
        end
        fprintf(fid, '%s %s\n', status_str, all_fullfileDirs_collected{i});
        fprintf(fid, '    %s\n\n', timestamp_check_results{i});
    end
    fclose(fid);
    fprintf('\nTimestamp check report saved to: %s\n', timestamp_report_filename);
else
    fprintf('\nWarning: Could not create timestamp check report file.\n');
end

fprintf('========================================================================\n');

% ========================================================================
% 生成b2fplasma文件状态报告
% ========================================================================
fprintf('\n========================================================================\n');
fprintf('B2FPLASMA FILE STATUS REPORT\n');
fprintf('========================================================================\n');

% 统计b2fplasma文件状态
total_cases_plasma = length(b2fplasma_file_exists);
existing_files = sum(b2fplasma_file_exists);
missing_files = total_cases_plasma - existing_files;

fprintf('Total cases processed: %d\n', total_cases_plasma);
fprintf('Cases with b2fplasma file present: %d\n', existing_files);
fprintf('Cases with b2fplasma file missing: %d\n', missing_files);

if missing_files > 0
    fprintf('\nCases with missing b2fplasma files:\n');
    fprintf('%-60s | %s\n', 'Directory', 'Status');
    fprintf('%s\n', repmat('-', 1, 120));
    for i = 1:total_cases_plasma
        if ~b2fplasma_file_exists(i)
            fprintf('%-60s | %s\n', all_fullfileDirs_collected{i}, b2fplasma_status_results{i});
        end
    end
end

% 生成b2fplasma文件状态报告文件
b2fplasma_report_filename = fullfile(pwd, ['b2fplasma_status_report_', currentDateTime, '.txt']);
counter = 1;
original_b2fplasma_filename = b2fplasma_report_filename;
while exist(b2fplasma_report_filename, 'file')
    [filepath, name, ext] = fileparts(original_b2fplasma_filename);
    b2fplasma_report_filename = fullfile(filepath, sprintf('%s_%d%s', name, counter, ext));
    counter = counter + 1;
end

% 写入b2fplasma文件状态报告文件
fid = fopen(b2fplasma_report_filename, 'w');
if fid ~= -1
    fprintf(fid, 'SOLPS b2fplasma File Status Report (Nitrogen Impurity)\n');
    fprintf(fid, 'Generated on: %s\n\n', char(datetime('now')));
    fprintf(fid, 'Total cases processed: %d\n', total_cases_plasma);
    fprintf(fid, 'Cases with b2fplasma file present: %d\n', existing_files);
    fprintf(fid, 'Cases with b2fplasma file missing: %d\n\n', missing_files);

    fprintf(fid, 'Detailed Results:\n');
    fprintf(fid, '%s\n', repmat('=', 1, 120));
    for i = 1:total_cases_plasma
        status_str = '';
        if b2fplasma_file_exists(i)
            status_str = '[FOUND]';
        else
            status_str = '[MISSING]';
        end
        fprintf(fid, '%s %s\n', status_str, all_fullfileDirs_collected{i});
        fprintf(fid, '    %s\n\n', b2fplasma_status_results{i});
    end

    if missing_files > 0
        fprintf(fid, '\nInterpretation:\n');
        fprintf(fid, '%s\n', repmat('=', 1, 50));
        fprintf(fid, 'Missing b2fplasma files may indicate:\n');
        fprintf(fid, '1. Simulation is still running\n');
        fprintf(fid, '2. Simulation terminated before completion\n');
        fprintf(fid, '3. Post-processing has not been performed\n');
        fprintf(fid, '4. File access or permission issues\n');
        fprintf(fid, '5. Directory structure problems (common in N impurity cases)\n\n');
        fprintf(fid, 'Recommendations:\n');
        fprintf(fid, '- Check simulation status for missing cases\n');
        fprintf(fid, '- Verify simulation completion\n');
        fprintf(fid, '- Consider re-running incomplete simulations\n');
        fprintf(fid, '- Check directory structure and file locations\n');
    end

    fclose(fid);
    fprintf('\nb2fplasma file status report saved to: %s\n', b2fplasma_report_filename);
else
    fprintf('\nWarning: Could not create b2fplasma status report file.\n');
end

% ========================================================================
% 生成重复算例分析报告
% ========================================================================
if global_index > 0
    generate_duplicate_case_analysis(all_fullfileDirs_collected(1:global_index));
end

fprintf('========================================================================\n');

% ========================================================================
% 接下来，进入循环，询问是否绘图，调用外部拆分脚本
% ========================================================================
while true
    fprintf('\n========================================================================\n');
    fprintf('  Plotting Options:\n');
    fprintf('========================================================================\n');
    fprintf('  1: Execute plotting scripts\n');
    fprintf('  r: Refresh plotting scripts (reload updated scripts)\n');
    fprintf('  0: Exit entire script execution\n');
    fprintf('========================================================================\n');

    plotting_choice = input('Please enter your choice: ', 's');

    if strcmpi(plotting_choice, '1')
        try
            exit_requested = select_and_execute_plotting_scripts_2(all_radiationData, groupDirs);
            if strcmpi(exit_requested, 'exit')
                fprintf('User requested to exit. Terminating script execution.\n');
                break;
            elseif strcmpi(exit_requested, 'refresh')
                % 自动执行刷新操作
                fprintf('========================================================================\n');
                fprintf('Auto-refreshing plotting scripts as requested...\n');
                clear select_and_execute_plotting_scripts_2; % 清除绘图脚本函数
                fprintf('Plotting scripts have been refreshed successfully!\n');
                fprintf('You can now execute updated plotting scripts.\n');
                fprintf('========================================================================\n');
            end
        catch ME
            % 捕获绘图脚本中的错误，不影响主脚本继续运行
            fprintf('\n========================================================================\n');
            fprintf('ERROR occurred in plotting script execution:\n');
            fprintf('Error Message: %s\n', ME.message);
            if ~isempty(ME.stack)
                fprintf('Error Location: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
            end
            fprintf('========================================================================\n');
            fprintf('The plotting script encountered an error, but the main script will continue running.\n');
            fprintf('You can try selecting other plotting options or refresh the scripts.\n');
            fprintf('========================================================================\n');
        end
    elseif strcmpi(plotting_choice, 'r')
        fprintf('Refreshing plotting scripts...\n');
        clear select_and_execute_plotting_scripts_2; % 清除绘图脚本函数
        fprintf('Plotting scripts refreshed. You can now execute updated scripts.\n');
    elseif strcmpi(plotting_choice, '0')
        fprintf('Exiting plotting options.\n');
        break;
    else
        fprintf('Invalid input, please enter 1, r, or 0.\n');
    end
end

fprintf('Script execution finished.\n');


% ======================== 保留的工具函数示例 ========================
function simplifiedDirName = generate_simplified_dir_name(dirPath)
    % --------------------------------------------------------------------
    % 根据目录路径，生成一个便于在图例中展示的简短名字
    % 例如：末两级目录名中含有数字的token、或"baseline"后缀等
    % --------------------------------------------------------------------
    pathParts = strsplit(dirPath, filesep);
    if length(pathParts) >= 2
        lastTwoParts = pathParts(end-1:end);
    else
        lastTwoParts = pathParts;
    end

     % secondLastPart 可能包含一些组合信息
    secondLastPart = lastTwoParts{1};
    tokens_secondLast = strsplit(secondLastPart, '_');
    selectedTokens_secondLast = {};
    for i_token = 1:length(tokens_secondLast)
        token = tokens_secondLast{i_token};
        % 仅保留包含数字的部分
        if ~isempty(regexp(token, '\d', 'once'))
            selectedTokens_secondLast{end+1} = token;
        end
    end

    % lastPart 通常是算例名字
    lastPart = lastTwoParts{2};
    baselineIndex = strfind(lastPart, 'baseline');
    if ~isempty(baselineIndex)
        contentAfterBaseline = lastPart(baselineIndex+length('baseline'):end);
        contentAfterBaseline = strrep(contentAfterBaseline, '_', ''); % 去掉下划线
        contentAfterBaseline = strtrim(contentAfterBaseline); % 去掉首尾空格
    else
        contentAfterBaseline = lastPart;
    end

    simplifiedDirName = [strjoin(selectedTokens_secondLast, '_'), '_', contentAfterBaseline];
end

% ======================== 错误诊断函数 ========================
function write_detailed_error_info(currentDir, missing_files, found_files, key_file_names)
    % --------------------------------------------------------------------
    % 生成详细的错误诊断信息并保存到文件
    % 输入参数：
    %   currentDir: 当前处理的目录
    %   missing_files: 缺失的文件列表
    %   found_files: 找到的文件映射
    %   key_file_names: 所有关键文件名列表
    % --------------------------------------------------------------------

    % 生成错误诊断文件名
    [~, dirName] = fileparts(currentDir);
    timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    error_filename = fullfile(pwd, sprintf('file_search_error_%s_%s.txt', dirName, timestamp));

    % 确保文件名唯一
    counter = 1;
    original_filename = error_filename;
    while exist(error_filename, 'file')
        [filepath, name, ext] = fileparts(original_filename);
        error_filename = fullfile(filepath, sprintf('%s_%d%s', name, counter, ext));
        counter = counter + 1;
    end

    % 写入详细的错误信息
    fid = fopen(error_filename, 'w');
    if fid ~= -1
        fprintf(fid, 'SOLPS File Search Error Report\n');
        fprintf(fid, '==============================\n\n');
        fprintf(fid, 'Generated on: %s\n', char(datetime('now')));
        fprintf(fid, 'Problem directory: %s\n\n', currentDir);

        fprintf(fid, 'Missing files:\n');
        for i = 1:length(missing_files)
            fprintf(fid, '  - %s\n', missing_files{i});
        end
        fprintf(fid, '\n');

        fprintf(fid, 'File search results:\n');
        fprintf(fid, '====================\n');
        for i = 1:length(key_file_names)
            file_name = key_file_names{i};
            if found_files.isKey(file_name) && ~isempty(found_files(file_name))
                fprintf(fid, '[FOUND] %s: %s\n', file_name, found_files(file_name));
            else
                fprintf(fid, '[MISSING] %s: Not found in any expected location\n', file_name);
            end
        end
        fprintf(fid, '\n');

        fprintf(fid, 'Directory structure analysis:\n');
        fprintf(fid, '============================\n');

        % 分析当前目录结构
        try
            currentDirContents = dir(currentDir);
            fprintf(fid, 'Contents of %s:\n', currentDir);
            for i = 1:length(currentDirContents)
                if ~strcmp(currentDirContents(i).name, '.') && ~strcmp(currentDirContents(i).name, '..')
                    if currentDirContents(i).isdir
                        fprintf(fid, '  [DIR]  %s\n', currentDirContents(i).name);
                    else
                        fprintf(fid, '  [FILE] %s\n', currentDirContents(i).name);
                    end
                end
            end
        catch
            fprintf(fid, 'Error reading directory contents of %s\n', currentDir);
        end

        fprintf(fid, '\n');

        % 分析父目录结构
        parentDir = fileparts(currentDir);
        if ~isempty(parentDir)
            try
                parentDirContents = dir(parentDir);
                fprintf(fid, 'Contents of parent directory %s:\n', parentDir);
                for i = 1:length(parentDirContents)
                    if ~strcmp(parentDirContents(i).name, '.') && ~strcmp(parentDirContents(i).name, '..')
                        if parentDirContents(i).isdir
                            fprintf(fid, '  [DIR]  %s\n', parentDirContents(i).name);
                        else
                            fprintf(fid, '  [FILE] %s\n', parentDirContents(i).name);
                        end
                    end
                end
            catch
                fprintf(fid, 'Error reading parent directory contents of %s\n', parentDir);
            end
        end

        fprintf(fid, '\nRecommendations:\n');
        fprintf(fid, '================\n');
        fprintf(fid, '1. Check if the simulation has completed successfully\n');
        fprintf(fid, '2. Verify that all required SOLPS-ITER output files are generated\n');
        fprintf(fid, '3. Check file permissions and accessibility\n');
        fprintf(fid, '4. Consider running the simulation again if files are missing\n');

        fclose(fid);
        fprintf('Detailed error information saved to: %s\n', error_filename);
    else
        fprintf('Warning: Could not create error diagnostic file.\n');
    end
end

% ========================================================================
% 辅助函数：生成重复算例分析报告
% ========================================================================
function generate_duplicate_case_analysis(processed_dirs)
    % 检查处理过的目录中是否存在重复

    fprintf('\n========================================================================\n');
    fprintf('DUPLICATE CASE ANALYSIS\n');
    fprintf('========================================================================\n');

    % 查找重复的目录路径
    [unique_dirs, ~, idx] = unique(processed_dirs);
    duplicate_indices = find(histcounts(idx, 1:length(unique_dirs)+1) > 1);

    if ~isempty(duplicate_indices)
        fprintf('Found %d duplicate case(s) in processed directories:\n\n', length(duplicate_indices));

        % 生成重复分析报告文件
        timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
        duplicate_report_filename = fullfile(pwd, sprintf('duplicate_case_analysis_%s.txt', timestamp));

        fid = fopen(duplicate_report_filename, 'w');
        if fid ~= -1
            fprintf(fid, 'Duplicate Case Analysis Report\n');
            fprintf(fid, 'Generated on: %s\n\n', char(datetime('now')));
            fprintf(fid, 'Total processed directories: %d\n', length(processed_dirs));
            fprintf(fid, 'Unique directories: %d\n', length(unique_dirs));
            fprintf(fid, 'Duplicate cases found: %d\n\n', length(duplicate_indices));

            fprintf(fid, 'Duplicate Cases:\n');
            fprintf(fid, '================\n');

            for i = 1:length(duplicate_indices)
                dup_idx = duplicate_indices(i);
                duplicate_dir = unique_dirs{dup_idx};
                occurrences = find(strcmp(processed_dirs, duplicate_dir));

                fprintf('Duplicate %d: %s\n', i, duplicate_dir);
                fprintf(fid, '%d. %s\n', i, duplicate_dir);
                fprintf(fid, '   Occurrences: %d times at positions: %s\n\n', ...
                        length(occurrences), mat2str(occurrences));
            end

            fclose(fid);
            fprintf('Duplicate analysis report saved to: %s\n', duplicate_report_filename);
        else
            fprintf('Warning: Could not create duplicate analysis report file.\n');
        end
    else
        fprintf('No duplicate cases found in processed directories.\n');
    end

    fprintf('========================================================================\n');
end
