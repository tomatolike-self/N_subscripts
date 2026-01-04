function plot_potential_ExB_flow_pattern_power_law(all_radiationData, domain, varargin)
% PLOT_POTENTIAL_EXB_FLOW_PATTERN_POWER_LAW
%   基于物理网格绘制电势分布 + ExB速度流型图（幂律映射箭头长度）。
%   背景色图：电势分布，使用 patch 将每个物理单元作为独立色块。
%   箭头：ExB速度（极向+径向），幂律映射箭头长度。
%
%   箭头缩放规则：
%     - 速度 < 1e3 m/s: 线性映射
%     - 速度 >= 1e3 m/s: 幂律映射 (指数 = log10(2))
%     - 参考: 1e3 m/s 对应 0.5 * max_cell_diagonal
%
%   可选参数：
%     'use_custom_colormap' (logical) - 是否加载 mycontour.mat 中的 colormap，默认 false。
%     'use_enhanced_arrows' (logical) - 是否使用增强型箭头，默认 false。
%     'clim_range' ([min, max]) - colorbar范围，默认 [-150, 150] V。

    if nargin < 2 || isempty(domain)
        domain = 0;
    end

    p = inputParser;
    addParameter(p, 'use_custom_colormap', false, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'use_enhanced_arrows', false, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'clim_range', [], @(x) isempty(x) || (isnumeric(x) && numel(x) == 2 && x(1) < x(2)));
    parse(p, varargin{:});

    use_custom_colormap = logical(p.Results.use_custom_colormap);
    use_enhanced_arrows = logical(p.Results.use_enhanced_arrows);
    clim_range = p.Results.clim_range;

    % 全局字体设置（与参考脚本保持一致）
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', 16);
    set(0, 'DefaultTextFontSize', 16);
    set(0, 'DefaultLineLineWidth', 1.5);
    set(0, 'DefaultLegendFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontSize', 14);
    set(0, 'DefaultTextInterpreter', 'latex');
    set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
    set(0, 'DefaultLegendInterpreter', 'latex');
    set(0, 'DefaultColorbarTickLabelInterpreter', 'latex');

    % Ne离子价态范围（Ne1+ 到 Ne10+）
    min_species_idx = 4;   % Ne1+
    max_species_idx = 13;  % Ne10+

    for i_case = 1:numel(all_radiationData)
        radData = all_radiationData{i_case};
        gmtry = radData.gmtry;
        plasma = radData.plasma;
        dirName = radData.dirName;

        fprintf('Processing case for Potential & ExB flow pattern (power law scale) on physical grid: %s\n', dirName);

        if ~isfield(gmtry, 'crx') || ~isfield(gmtry, 'cry')
            warning('Case %s: gmtry.crx / gmtry.cry not found. Skipping.', dirName);
            continue;
        end

        nx_orig = size(gmtry.crx, 1);
        ny_orig = size(gmtry.crx, 2);

        if nx_orig < 3 || ny_orig < 3
            warning('Case %s: grid too small (nx=%d, ny=%d). Skipping.', dirName, nx_orig, ny_orig);
            continue;
        end

        ix_core = 2:nx_orig-1;
        iy_core = 2:ny_orig-1;

        % 检查电势数据
        if ~isfield(plasma, 'po')
            warning('Case %s: plasma.po (potential) missing. Skipping.', dirName);
            continue;
        end

        % 检查ExB速度数据
        if ~isfield(plasma, 'vaecrb')
            warning('Case %s: plasma.vaecrb (ExB velocity) missing. Skipping.', dirName);
            continue;
        end

        % 提取电势数据（去除保护单元）
        potential_full = plasma.po;
        potential_core = potential_full(ix_core, iy_core);

        % 计算ExB速度（使用Ne离子的ExB速度，所有价态的ExB速度相同）
        % 使用Ne1+的ExB速度数据（索引4）
        species_idx = min_species_idx;  % Ne1+
        if size(plasma.vaecrb, 4) < species_idx
            warning('Case %s: vaecrb species index %d not found. Skipping.', dirName, species_idx);
            continue;
        end

        % 提取ExB极向和径向速度
        vexb_pol_full = plasma.vaecrb(:, :, 1, species_idx);
        vexb_rad_full = plasma.vaecrb(:, :, 2, species_idx);
        vexb_pol_core = vexb_pol_full(ix_core, iy_core);
        vexb_rad_core = vexb_rad_full(ix_core, iy_core);

        % 检查有效数据
        finite_mask = isfinite(potential_core);
        if ~any(finite_mask(:))
            warning('Case %s: no finite potential values after removing guard cells. Skipping.', dirName);
            continue;
        end

        % 处理电势数据用于绘图
        potential_for_plot = potential_core;
        potential_for_plot(~isfinite(potential_for_plot)) = 0;

        % 设置电势colorbar范围
        if ~isempty(clim_range)
            clim_min = clim_range(1);
            clim_max = clim_range(2);
        else
            clim_min = -150;
            clim_max = 150;
        end

        % 处理ExB速度数据
        vexb_pol_core(~isfinite(vexb_pol_core)) = 0;
        vexb_rad_core(~isfinite(vexb_rad_core)) = 0;

        % 获取极向和径向单位矢量
        [epx, epy, erx, ery] = mshproj(gmtry);
        epx_core = epx(ix_core, iy_core);
        epy_core = epy(ix_core, iy_core);
        erx_core = erx(ix_core, iy_core);
        ery_core = ery(ix_core, iy_core);

        % 计算ExB速度在笛卡尔坐标系中的分量
        vx_exb = vexb_pol_core .* epx_core + vexb_rad_core .* erx_core;
        vy_exb = vexb_pol_core .* epy_core + vexb_rad_core .* ery_core;

        % 计算速度大小
        velocity_magnitude = sqrt(vexb_pol_core.^2 + vexb_rad_core.^2);
        max_vel_val = max(velocity_magnitude(:));

        if max_vel_val <= 0 || ~isfinite(max_vel_val)
            warning('Case %s: all ExB velocity values are zero. Only potential will be drawn.', dirName);
        end

        % 计算网格中心坐标
        rc = mean(gmtry.crx, 3);
        zc = mean(gmtry.cry, 3);
        rc_core = rc(ix_core, iy_core);
        zc_core = zc(ix_core, iy_core);

        % 提取角点坐标
        crx_core = gmtry.crx(ix_core, iy_core, :);
        cry_core = gmtry.cry(ix_core, iy_core, :);

        % 计算单元对角线长度（用于箭头缩放）
        cell_diag = sqrt((crx_core(:, :, 3) - crx_core(:, :, 1)).^2 + (cry_core(:, :, 3) - cry_core(:, :, 1)).^2);
        max_cell_diag = max(cell_diag(:));

        domain_diag = hypot(max(rc_core(:)) - min(rc_core(:)), max(zc_core(:)) - min(zc_core(:)));
        if ~isfinite(max_cell_diag) || max_cell_diag <= 0
            max_cell_diag = max(domain_diag * 0.08, 1e-3);
        end
        if ~isfinite(domain_diag) || domain_diag <= 0
            domain_diag = 1.0;
        end

        % 应用分段幂律映射计算箭头长度
        [vx_scaled, vy_scaled] = applyPowerLawScaling(vx_exb, vy_exb, velocity_magnitude, max_cell_diag);
        zero_vel_mask = velocity_magnitude == 0;
        vx_scaled(zero_vel_mask) = 0;
        vy_scaled(zero_vel_mask) = 0;

        % 创建图形
        fig_title = sprintf('Potential & ExB Flow Pattern (Physical Grid, Power Law) - %s', dirName);
        figure('Name', fig_title, ...
               'NumberTitle', 'off', ...
               'Color', 'w', ...
               'Units', 'inches', 'Position', [1, 1, 14, 10]);
        ax = gca;
        hold(ax, 'on');

        % --- 物理网格色块绘制（每个单元统一颜色） ---
        [X_patch, Y_patch, C_patch] = buildCellFlatPatch(crx_core, cry_core, potential_for_plot);
        patch(ax, X_patch, Y_patch, C_patch, ...
              'FaceColor', 'flat', 'EdgeColor', 'none', 'FaceAlpha', 1.0, 'CDataMapping', 'scaled');

        % 设置colorbar范围（线性刻度）
        clim(ax, [clim_min, clim_max]);

        if use_custom_colormap
            try
                load('mycontour.mat', 'mycontour');
                colormap(ax, mycontour);
                fprintf('  Using custom colormap from mycontour.mat\n');
            catch ME
                fprintf('  Warning: failed to load mycontour.mat (%s). Using default jet colormap.\n', ME.message);
                colormap(ax, 'jet');
            end
        else
            colormap(ax, 'jet');
        end

        h_cb = colorbar(ax);
        ylabel(h_cb, 'Potential $\phi$ (V)', 'Interpreter', 'latex', 'FontSize', 16);

        % 叠加网格结构
        try
            plot3sep(gmtry, 'color', 'k', 'LineStyle', '--', 'LineWidth', 1.0, 'HandleVisibility', 'off');
        catch
        end
        try
            plotgrid_new(gmtry, 'all3', 'color', [0.3 0.3 0.3], 'LineWidth', 0.2, 'HandleVisibility', 'off');
        catch
        end
        try
            plotplasmaboundary(gmtry, 'color', 'k', 'LineStyle', '-', 'LineWidth', 1.0, 'HandleVisibility', 'off');
        catch
        end

        % 绘制ExB速度箭头（幂律映射）
        if max_vel_val > 0 && isfinite(max_vel_val)
            if use_enhanced_arrows
                drawEnhancedArrows(ax, rc_core, zc_core, vx_scaled, vy_scaled, 'k', 1.5);
            else
                quiver(ax, rc_core, zc_core, vx_scaled, vy_scaled, ...
                       'Color', 'k', 'AutoScale', 'off', 'LineWidth', 0.7, 'MaxHeadSize', 0.8);
            end

            % 添加速度图例
            vel_ticks = velocityLegendTicks(max_vel_val);
            if ~isempty(vel_ticks)
                r_range = [min(rc_core(:)), max(rc_core(:))];
                z_range = [min(zc_core(:)), max(zc_core(:))];
                legend_pos_r = r_range(1) + 0.7 * (r_range(2) - r_range(1));
                legend_pos_z = z_range(1) + 0.92 * (z_range(2) - z_range(1));
                legend_spacing = 0.04 * domain_diag;

                text(ax, legend_pos_r, legend_pos_z + legend_spacing, ...
                     'ExB Velocity (m/s, Power Law):', ...
                     'Color', 'r', 'FontSize', 15, 'FontWeight', 'bold', 'Interpreter', 'latex', ...
                     'HorizontalAlignment', 'left');

                max_tick_arrow = 0;
                legend_arrow_lengths = zeros(size(vel_ticks));
                for i_tick = 1:numel(vel_ticks)
                    tick_val = vel_ticks(i_tick);
                    [arrow_x, ~] = applyPowerLawScaling(tick_val, 0, tick_val, max_cell_diag);
                    legend_arrow_lengths(i_tick) = arrow_x;
                    max_tick_arrow = max(max_tick_arrow, arrow_x);
                end

                for i_tick = 1:numel(vel_ticks)
                    tick_val = vel_ticks(i_tick);
                    arrow_len = legend_arrow_lengths(i_tick);
                    z_pos = legend_pos_z - (i_tick - 1) * legend_spacing;
                    quiver(ax, legend_pos_r, z_pos, arrow_len, 0, ...
                           'Autoscale', 'off', 'Color', 'r', 'LineWidth', 1.5, 'MaxHeadSize', 4);
                    text(ax, legend_pos_r + max_tick_arrow * 1.05, z_pos, ...
                         sprintf('%.1e', tick_val), ...
                         'Color', 'r', 'FontSize', 13, 'Interpreter', 'latex', ...
                         'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left');
                end
            end
        else
            fprintf('  Info: ExB velocity arrows skipped due to zero velocity.\n');
        end

        xlabel(ax, '$R$ (m)', 'Interpreter', 'latex', 'FontSize', 18);
        ylabel(ax, '$Z$ (m)', 'Interpreter', 'latex', 'FontSize', 18);
        axis(ax, 'equal');
        axis(ax, 'tight');
        grid(ax, 'on');
        box(ax, 'on');

        % 根据 domain 裁剪可视区域
        if domain ~= 0
            switch domain
                case 1
                    xlim(ax, [1.30, 2.00]);
                    ylim(ax, [0.50, 1.20]);
                case 2
                    xlim(ax, [1.30, 2.05]);
                    ylim(ax, [-1.15, -0.40]);
            end

            if isfield(radData, 'structure')
                plotstructure(radData.structure, 'color', 'k', 'LineWidth', 2, 'HandleVisibility', 'off');
            end
        end

        % 添加数据提示功能
        dcm_obj = datacursormode(gcf);
        set(dcm_obj, 'UpdateFcn', {@myDataCursorUpdateFcn_PotentialExB, rc_core, zc_core, ...
                                   potential_core, vexb_pol_core, vexb_rad_core});

        saveFigureWithTimestamp(gcf, sprintf('Potential_ExB_FlowPattern_PowerLaw_Physical_%s', createSafeFilename(dirName)));
        hold(ax, 'off');
    end

    fprintf('Potential & ExB flow pattern (physical grid, power law scale) plotting completed.\n');
end

function [vx_scaled, vy_scaled] = applyPowerLawScaling(vx, vy, velocity_magnitude, max_cell_diag)
% 应用分段幂律映射计算箭头长度
% 参数:
%   vx, vy - 速度的x和y分量
%   velocity_magnitude - 速度大小
%   max_cell_diag - 最大单元对角线长度（用于参考长度）
%
% 映射规则:
%   阈值: 1e3 m/s
%   参考长度: 1e3 m/s对应 sqrt(2) * 0.5
%   低于1e3: 线性映射
%   高于1e3: 幂律映射 (指数 = log10(2))

    velocity_threshold = 1e3;  % 分段阈值: 1e3 m/s
    reference_length = sqrt(2) * 0.5;  % 1e3 m/s对应的箭头长度

    % 幂律模型参数
    m = log10(2);  % 幂律指数
    k = reference_length / (10^(3 * m));  % 等价于 reference_length / (2^3)

    % 计算箭头长度
    arrow_lengths = zeros(size(velocity_magnitude));

    % 高速度区域（≥1e3 m/s）：使用幂律模型
    high_vel_idx = velocity_magnitude >= velocity_threshold;
    arrow_lengths(high_vel_idx) = k .* (velocity_magnitude(high_vel_idx) .^ m);

    % 低速度区域（<1e3 m/s）：基于1e3的箭头长度进行线性映射
    low_vel_idx = (velocity_magnitude > 0) & (velocity_magnitude < velocity_threshold);
    reference_length_at_threshold = k * (velocity_threshold^m);
    arrow_lengths(low_vel_idx) = reference_length_at_threshold * (velocity_magnitude(low_vel_idx) / velocity_threshold);

    % 计算缩放后的向量分量
    velocity_for_direction = velocity_magnitude;
    is_zero_vel = (velocity_for_direction == 0);
    velocity_for_direction(is_zero_vel) = 1;  % 避免除以零

    vx_scaled = (vx ./ velocity_for_direction) .* arrow_lengths;
    vy_scaled = (vy ./ velocity_for_direction) .* arrow_lengths;

    vx_scaled(is_zero_vel) = 0;
    vy_scaled(is_zero_vel) = 0;
end

function ticks = velocityLegendTicks(max_vel_val)
    if max_vel_val <= 0 || ~isfinite(max_vel_val)
        ticks = [];
        return;
    end
    base_ticks = [1, 0.5, 0.1] * max_vel_val;
    ticks = unique(base_ticks(base_ticks > 0));
end

function [X_patch, Y_patch, C_patch] = buildCellFlatPatch(crx_core, cry_core, data_core)
    [nx_core, ny_core, ~] = size(crx_core);
    num_cells = nx_core * ny_core;
    X_patch = zeros(4, num_cells);
    Y_patch = zeros(4, num_cells);
    C_patch = zeros(4, num_cells);

    cell_idx = 0;
    for ix = 1:nx_core
        for iy = 1:ny_core
            cell_idx = cell_idx + 1;
            xv = squeeze(crx_core(ix, iy, [1, 2, 4, 3]));
            yv = squeeze(cry_core(ix, iy, [1, 2, 4, 3]));
            X_patch(:, cell_idx) = xv;
            Y_patch(:, cell_idx) = yv;
            C_patch(:, cell_idx) = data_core(ix, iy);
        end
    end
end

function drawEnhancedArrows(ax, X, Y, U, V, color, linewidth)
% 绘制增强型箭头（使用patch绘制三角形箭头帽）
    X = X(:);
    Y = Y(:);
    U = U(:);
    V = V(:);

    arrow_length = sqrt(U.^2 + V.^2);
    valid_idx = arrow_length > 0;

    X = X(valid_idx);
    Y = Y(valid_idx);
    U = U(valid_idx);
    V = V(valid_idx);
    arrow_length = arrow_length(valid_idx);

    U_norm = U ./ arrow_length;
    V_norm = V ./ arrow_length;

    U_perp = -V_norm;
    V_perp = U_norm;

    for i = 1:numel(X)
        x0 = X(i);
        y0 = Y(i);
        u = U(i);
        v = V(i);
        len = arrow_length(i);

        x1 = x0 + u;
        y1 = y0 + v;

        plot(ax, [x0, x1], [y0, y1], 'Color', color, 'LineWidth', linewidth);

        head_len = min(len * 0.25, len);
        head_width = head_len * 0.4;

        if head_len > 0
            u_n = U_norm(i);
            v_n = V_norm(i);
            u_p = U_perp(i);
            v_p = V_perp(i);

            tip_x = x1;
            tip_y = y1;
            base_x = x1 - head_len * u_n;
            base_y = y1 - head_len * v_n;
            left_x = base_x + head_width * u_p;
            left_y = base_y + head_width * v_p;
            right_x = base_x - head_width * u_p;
            right_y = base_y - head_width * v_p;

            patch(ax, [tip_x, left_x, right_x], [tip_y, left_y, right_y], ...
                  color, 'EdgeColor', color, 'LineWidth', linewidth * 0.5);
        end
    end
end

function output_txt = myDataCursorUpdateFcn_PotentialExB(~, event_obj, rc_core, zc_core, potential_core, vexb_pol_core, vexb_rad_core)
    pos = event_obj.Position;
    R = pos(1);
    Z = pos(2);

    distance_sq = (rc_core - R).^2 + (zc_core - Z).^2;
    [~, linear_idx] = min(distance_sq(:));
    [ix, iy] = ind2sub(size(distance_sq), linear_idx);

    potential_val = potential_core(ix, iy);
    vexb_pol_val = vexb_pol_core(ix, iy);
    vexb_rad_val = vexb_rad_core(ix, iy);

    output_txt = {
        sprintf('R = %.4f m', R);
        sprintf('Z = %.4f m', Z);
        sprintf('i_x = %d', ix + 1);
        sprintf('i_y = %d', iy + 1);
        sprintf('\\phi = %.2f V', potential_val);
        sprintf('v_{ExB,pol} = %.3e m/s', vexb_pol_val);
        sprintf('v_{ExB,rad} = %.3e m/s', vexb_rad_val)
    };
end

function safeName = createSafeFilename(originalName)
    safeName = regexprep(originalName, '[^a-zA-Z0-9_\-\.]', '_');
    if strlength(safeName) > 100
        safeName = safeName(1:100);
    end
end

function saveFigureWithTimestamp(figHandle, baseName)
    set(figHandle, 'PaperPositionMode', 'auto');
    timestampStr = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    figFile = sprintf('%s_%s.fig', baseName, timestampStr);
    try
        savefig(figHandle, figFile);
        fprintf('  Figure saved: %s\n', figFile);
    catch ME
        fprintf('  Warning: failed to save figure (%s).\n', ME.message);
    end
end

