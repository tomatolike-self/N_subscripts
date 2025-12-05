function plot_core_region_impurity_charge_state_fraction_bar_N(all_radiationData, groupDirs, usePresetLegends)
% PLOT_CORE_REGION_IMPURITY_CHARGE_STATE_FRACTION_BAR_N
%   N 杂质版：绘制芯部区域 N1+~N7+ 占比的归一化堆叠柱状图（每个算例一根柱）。
%   计算方式：积分 density * volume（裁剪保护单元，芯部极向 25-72，径向 1-12），
%   然后对每个算例的总量归一化。

    if nargin < 2 || isempty(groupDirs)
        groupDirs = {collectAllDirNames(all_radiationData)};
    end
    if nargin < 3 || isempty(usePresetLegends)
        usePresetLegends = false;
    end

    fprintf('\n=== Generating core-region N charge-state fraction chart (N1+-N7+) ===\n');

    setupPlotDefaults();
    C = getGridRegionConstants();

    case_records = gatherCaseRecords(all_radiationData, groupDirs, usePresetLegends, C);
    num_cases = numel(case_records);
    if num_cases == 0
        warning('No valid cases found for plotting.');
        return;
    end

    % 动态确定实际可用的最高价态（<=7）
    max_charge_state = 0;
    for i = 1:num_cases
        max_charge_state = max(max_charge_state, numel(case_records(i).fractions));
    end
    max_charge_state = min(max_charge_state, 7);
    if max_charge_state == 0
        warning('No valid charge-state data found.');
        return;
    end

    % 构建 [num_states x num_cases] 矩阵（不足的用 0 补齐）
    fractions_matrix = zeros(max_charge_state, num_cases);
    for i = 1:num_cases
        f = case_records(i).fractions;
        fractions_matrix(1:numel(f), i) = f(:);
    end

    case_labels = {case_records.label};

    createFractionStackedBar(fractions_matrix, case_labels, max_charge_state);
    saveFigureWithTimestamp('Core_Region_N_Charge_State_Fraction');

    fprintf('=== Core-region N charge-state fraction chart completed ===\n');
end

%% ========== 配置与数据收集 ==========
function setupPlotDefaults()
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', 18);
    set(0, 'DefaultTextFontSize', 18);
    set(0, 'DefaultLineLineWidth', 1.5);
    set(0, 'DefaultLegendFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontSize', 16);
    set(0, 'DefaultTextInterpreter', 'latex');
    set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
    set(0, 'DefaultLegendInterpreter', 'latex');
    set(0, 'DefaultColorbarTickLabelInterpreter', 'latex');
end

function dirNames = collectAllDirNames(all_radiationData)
    dirNames = cell(1, numel(all_radiationData));
    for i = 1:numel(all_radiationData)
        dirNames{i} = all_radiationData{i}.dirName;
    end
end

function C = getGridRegionConstants()
    C.outer_div_end    = 24;
    C.inner_div_start  = 73;
    C.separatrix_line  = 12;
end

function case_records = gatherCaseRecords(all_radiationData, groupDirs, usePresetLegends, C)
    case_records = struct('fractions', {}, 'total_amount', {}, ...
                          'label', {}, 'group_index', {}, 'case_in_group', {});
    record_counter = 0;

    for g = 1:numel(groupDirs)
        currentGroup = groupDirs{g};
        if ~iscell(currentGroup)
            currentGroup = {currentGroup};
        end

        for k = 1:numel(currentGroup)
            targetDir = currentGroup{k};
            data_idx = findDirIndexInRadiationData(all_radiationData, targetDir);
            if data_idx <= 0
                fprintf('Warning: Directory %s not found in all_radiationData. Skipping.\n', targetDir);
                continue;
            end

            radData = all_radiationData{data_idx};
            [fractions, total_amount] = computeCoreChargeFractions(radData, C);
            if isempty(fractions)
                fprintf('Warning: Case %s did not yield valid core-region fractions. Skipping.\n', radData.dirName);
                continue;
            end

            record_counter = record_counter + 1;
            case_records(record_counter).fractions = fractions;
            case_records(record_counter).total_amount = total_amount;
            case_records(record_counter).label = determineCaseLabel(radData.dirName, k, usePresetLegends);
            case_records(record_counter).group_index = g;
            case_records(record_counter).case_in_group = k;
        end
    end
end

function idx = findDirIndexInRadiationData(all_radiationData, targetDir)
    idx = 0;
    for i = 1:numel(all_radiationData)
        if strcmp(all_radiationData{i}.dirName, targetDir)
            idx = i;
            return;
        end
    end
end

function label = determineCaseLabel(dirName, caseNumber, usePresetLegends)
    presetLabels = {'fav. B_T', 'unfav. B_T', 'w/o drift'};
    if usePresetLegends && caseNumber <= numel(presetLabels)
        label = presetLabels{caseNumber};
    else
        label = getShortDirName(dirName);
    end
end

function shortName = getShortDirName(fullDirName)
    [~, shortName] = fileparts(fullDirName);
    maxLength = 36;
    if numel(shortName) > maxLength
        shortName = shortName(1:maxLength);
    end
end

%% ========== 计算芯部占比 ==========
function [fractions, total_amount] = computeCoreChargeFractions(radData, C)
    fractions = [];
    total_amount = NaN;

    if ~isfield(radData, 'plasma') || ~isfield(radData.plasma, 'na')
        return;
    end
    if ~isfield(radData, 'gmtry') || ~isfield(radData.gmtry, 'vol')
        return;
    end

    plasma = radData.plasma;
    gmtry = radData.gmtry;

    if any(size(gmtry.vol) < [3, 3])
        return;
    end

    vol_trimmed = gmtry.vol(2:end-1, 2:end-1); % 去除保护单元

    sample_species_idx = min(size(plasma.na, 3), 4);
    data_sample = plasma.na(:,:,sample_species_idx);
    data_trim_template = data_sample(2:end-1, 2:end-1);

    nx_trimmed = min(size(vol_trimmed, 1), size(data_trim_template, 1));
    ny_trimmed = min(size(vol_trimmed, 2), size(data_trim_template, 2));
    if nx_trimmed <= 0 || ny_trimmed <= 0
        return;
    end

    vol_trimmed = vol_trimmed(1:nx_trimmed, 1:ny_trimmed);

    core_pol_start = min(max(C.outer_div_end + 1, 1), nx_trimmed);
    core_pol_end   = min(max(C.inner_div_start - 1, core_pol_start), nx_trimmed);
    core_rad_end   = min(max(C.separatrix_line, 1), ny_trimmed);
    if core_pol_end < core_pol_start || core_rad_end < 1
        return;
    end

    core_pol_range = core_pol_start:core_pol_end;
    core_rad_range = 1:core_rad_end;

    max_charge_states = min(7, max(0, size(plasma.na,3) - 3)); % 最多 N7+
    if max_charge_states < 1
        return;
    end

    counts = zeros(1, max_charge_states);
    for charge_state = 1:max_charge_states
        species_idx = charge_state + 3;  % N1+ -> idx 4
        species_data_full = plasma.na(:,:,species_idx);
        species_trimmed = species_data_full(2:end-1, 2:end-1);
        species_trimmed = species_trimmed(1:nx_trimmed, 1:ny_trimmed);

        region_density = species_trimmed(core_pol_range, core_rad_range);
        region_volume  = vol_trimmed(core_pol_range, core_rad_range);
        counts(charge_state) = sum(region_density .* region_volume, 'all', 'omitnan');
    end

    total_amount = sum(counts, 'omitnan');
    if total_amount > 0
        fractions = counts ./ total_amount;
    else
        fractions = zeros(1, max_charge_states);
    end
end

%% ========== 绘图 ==========
function createFractionStackedBar(fractions_matrix, case_labels, max_charge_state)
    [num_states, num_cases] = size(fractions_matrix);

    figure('Name', 'Core Region N Charge-State Fractions', 'Color', 'w', 'Position', [100, 100, 1200, 600]);
    hb = bar(fractions_matrix', 'stacked');

    cmap = lines(num_states);
    for i = 1:min(num_states, numel(hb))
        set(hb(i), 'FaceColor', cmap(i, :));
    end

    set(gca, 'XTick', 1:num_cases, 'XTickLabel', case_labels, ...
        'XTickLabelRotation', 45, 'FontSize', 12);
    ylim([0, 1]);
    ylabel('Fraction (normalized)', 'FontSize', 14);
    xlabel('Cases', 'FontSize', 14);
    grid on;

    legend_entries = cell(1, num_states);
    for i = 1:num_states
        % 对应 N1+~N7+，使用 latex 解释器时需要用 $ 包裹数学公式
        legend_entries{i} = sprintf('$\\mathrm{N}^{%d+}$', i);
    end
    lgd = legend(legend_entries, 'Location', 'bestoutside', 'Interpreter', 'latex');
    set(lgd, 'FontSize', 12);
end

function saveFigureWithTimestamp(baseName)
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    fname = sprintf('%s_%s.fig', baseName, timestamp);
    savefig(fname);
    fprintf('Figure saved as %s\n', fname);
end
