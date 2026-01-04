function plot_potential_ExB_flow_pattern(all_radiationData, domain, varargin)
% PLOT_POTENTIAL_EXB_FLOW_PATTERN
%   基于物理网格绘制电势分布 + ExB速度流型图（单元块颜色保持一致）。
%   背景色图：电势分布，使用 patch 将每个物理单元作为独立色块。
%   箭头：ExB速度（极向 + 径向分量），线性缩放箭头长度。
%
%   可选参数：
%     'use_custom_colormap' (logical) - 是否加载 mycontour.mat 中的 colormap，默认 false。
%     'use_enhanced_arrows' (logical) - 是否使用增强型箭头（更清晰的箭头帽），默认 false。
%     'clim_range' (numeric array) - colorbar范围，[min, max]，空数组表示使用默认自动缩放（默认[]）。

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

    % 全局字体设置（增大字体以适应A4双栏印刷）
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', 20);
    set(0, 'DefaultTextFontSize', 20);
    set(0, 'DefaultLineLineWidth', 2.0);
    set(0, 'DefaultLegendFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontSize', 18);
    set(0, 'DefaultTextInterpreter', 'latex');
    set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
    set(0, 'DefaultLegendInterpreter', 'latex');
    set(0, 'DefaultColorbarTickLabelInterpreter', 'latex');

    for i_case = 1:numel(all_radiationData)
        radData = all_radiationData{i_case};
        gmtry = radData.gmtry;
        plasma = radData.plasma;
        dirName = radData.dirName;

        fprintf('Processing case for Potential & ExB flow pattern (cell-flat color) on physical grid: %s\n', dirName);

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

        if ~isfield(plasma, 'po')
            warning('Case %s: plasma.po (potential) missing. Skipping.', dirName);
            continue;
        end

        if ~isfield(plasma, 'vaecrb')
            warning('Case %s: plasma.vaecrb (ExB velocity) missing. Skipping.', dirName);
            continue;
        end

        % 使用主离子（D+，种类索引2）的ExB速度
        % vaecrb 维度: (nx, ny, 2, nspecies)
        % 第三维: 1=极向, 2=径向
        species_idx = 2; % D+ 主离子
        if size(plasma.vaecrb, 4) < species_idx
            warning('Case %s: Species index %d not found in vaecrb. Skipping.', dirName, species_idx);
            continue;
        end

        potential_full = plasma.po;
        vexb_pol_full = plasma.vaecrb(:, :, 1, species_idx);
        vexb_rad_full = plasma.vaecrb(:, :, 2, species_idx);

        potential_core = potential_full(ix_core, iy_core);
        vexb_pol_core = vexb_pol_full(ix_core, iy_core);
        vexb_rad_core = vexb_rad_full(ix_core, iy_core);

        finite_mask = isfinite(potential_core);
        if ~any(finite_mask(:))
            warning('Case %s: no finite potential values after removing guard cells. Skipping.', dirName);
            continue;
        end

        potential_for_plot = potential_core;
        potential_for_plot(~isfinite(potential_for_plot)) = 0;

        % 设置colorbar范围（使用用户指定的范围或默认自动缩放）
        if ~isempty(clim_range)
            clim_min = clim_range(1);
            clim_max = clim_range(2);
        else
            clim_min = -150;
            clim_max = 150;
        end

        vexb_pol_core(~isfinite(vexb_pol_core)) = 0;
        vexb_rad_core(~isfinite(vexb_rad_core)) = 0;

        [epx, epy, erx, ery] = mshproj(gmtry);
        epx_core = epx(ix_core, iy_core);
        epy_core = epy(ix_core, iy_core);
        erx_core = erx(ix_core, iy_core);
        ery_core = ery(ix_core, iy_core);

        vx_exb = vexb_pol_core .* epx_core + vexb_rad_core .* erx_core;
        vy_exb = vexb_pol_core .* epy_core + vexb_rad_core .* ery_core;
        exb_magnitude = sqrt(vexb_pol_core.^2 + vexb_rad_core.^2);
        max_exb_val = max(exb_magnitude(:));

        if max_exb_val <= 0 || ~isfinite(max_exb_val)
            warning('Case %s: all ExB velocity values are zero. Only potential will be drawn.', dirName);
        end

        rc = mean(gmtry.crx, 3);
        zc = mean(gmtry.cry, 3);
        rc_core = rc(ix_core, iy_core);
        zc_core = zc(ix_core, iy_core);

        crx_core = gmtry.crx(ix_core, iy_core, :);
        cry_core = gmtry.cry(ix_core, iy_core, :);

        cell_diag = sqrt((crx_core(:, :, 3) - crx_core(:, :, 1)).^2 + (cry_core(:, :, 3) - cry_core(:, :, 1)).^2);
        max_cell_diag = max(cell_diag(:));

        domain_diag = hypot(max(rc_core(:)) - min(rc_core(:)), max(zc_core(:)) - min(zc_core(:)));
        if ~isfinite(max_cell_diag) || max_cell_diag <= 0
            max_cell_diag = max(domain_diag * 0.08, 1e-3);
        end
        if ~isfinite(domain_diag) || domain_diag <= 0
            domain_diag = 1.0;
        end

        if max_exb_val > 0 && isfinite(max_exb_val)
            scale_factor = max_cell_diag / max_exb_val;
        else
            scale_factor = 0;
        end

        vx_scaled = vx_exb * scale_factor;
        vy_scaled = vy_exb * scale_factor;
        zero_exb_mask = exb_magnitude == 0;
        vx_scaled(zero_exb_mask) = 0;
        vy_scaled(zero_exb_mask) = 0;

        fig_title = sprintf('Potential & ExB Flow Pattern - %s', dirName);
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

        set(ax, 'ColorScale', 'linear');
        caxis(ax, [clim_min, clim_max]);

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
        h_cb.FontSize = 18;  % 增大colorbar刻度标签字体

        ylabel(h_cb, '$\phi$ (V)', 'Interpreter', 'latex', 'FontSize', 20);

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

        % 先绘制ExB速度箭头（但不绘制图例）
        if scale_factor > 0
            if use_enhanced_arrows
                % 使用增强型箭头（自定义绘制，箭头帽更清晰）
                drawEnhancedArrows(ax, rc_core, zc_core, vx_scaled, vy_scaled, 'k', 1.5);
            else
                % 使用标准quiver箭头，但增大箭头帽
                quiver(ax, rc_core, zc_core, vx_scaled, vy_scaled, ...
                       'Color', 'k', 'AutoScale', 'off', 'LineWidth', 1.5, ...
                       'MaxHeadSize', 2.5, 'AutoScaleFactor', 1.0);
            end
        else
            fprintf('  Info: ExB velocity arrows skipped due to zero total velocity.\n');
        end

        xlabel(ax, '$R$ (m)', 'Interpreter', 'latex', 'FontSize', 22);
        ylabel(ax, '$Z$ (m)', 'Interpreter', 'latex', 'FontSize', 22);
        axis(ax, 'equal');
        axis(ax, 'tight');
        grid(ax, 'on');
        box(ax, 'on');

        % 增大坐标轴刻度标签字体
        ax.FontSize = 18;

        % 根据 domain 裁剪可视区域
        if domain ~= 0
            switch domain
                case 1
                    xlim(ax, [1.40, 1.90]);
                    ylim(ax, [0.60, 1.10]);
                case 2
                    xlim(ax, [1.30, 2.05]);
                    ylim(ax, [-1.15, -0.40]);
            end

            if isfield(radData, 'structure')
                plotstructure(radData.structure, 'color', 'k', 'LineWidth', 2, 'HandleVisibility', 'off');
            end
        end

        % 在domain裁剪后绘制ExB速度图例，确保图例位置基于当前视图范围
        if scale_factor > 0
            exb_ticks = exbLegendTicks(max_exb_val);
            if ~isempty(exb_ticks)
                % 获取当前视图范围（裁剪后的范围）
                current_xlim = xlim(ax);
                current_ylim = ylim(ax);
                current_r_range = current_xlim;
                current_z_range = current_ylim;

                % 基于当前视图范围计算图例位置
                % 根据domain调整图例的R方向位置
                if domain == 1
                    legend_r_ratio = 0.75;  % domain=1时向右移动
                else
                    legend_r_ratio = 0.65;  % 其他情况保持原位置
                end
                legend_pos_r = current_r_range(1) + legend_r_ratio * (current_r_range(2) - current_r_range(1));
                legend_pos_z = current_z_range(1) + 0.88 * (current_z_range(2) - current_z_range(1));

                % 计算图例间距（基于当前视图的对角线）
                current_domain_diag = hypot(current_r_range(2) - current_r_range(1), ...
                                           current_z_range(2) - current_z_range(1));
                legend_spacing = 0.06 * current_domain_diag;

                text(ax, legend_pos_r, legend_pos_z + legend_spacing, ...
                     'ExB Velocity ($\mathrm{m/s}$):', ...
                     'Color', 'r', 'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'latex', ...
                     'HorizontalAlignment', 'left');

                max_tick_arrow = 0;
                for i_tick = 1:numel(exb_ticks)
                    tick_val = exb_ticks(i_tick);
                    arrow_len = tick_val * scale_factor;
                    max_tick_arrow = max(max_tick_arrow, arrow_len);
                    z_pos = legend_pos_z - (i_tick - 1) * legend_spacing;
                    % 使用增强的箭头样式，箭头帽更明显
                    quiver(ax, legend_pos_r, z_pos, arrow_len, 0, ...
                           'Autoscale', 'off', 'Color', 'r', 'LineWidth', 2.5, ...
                           'MaxHeadSize', 5.0, 'AutoScaleFactor', 1.0);
                    text(ax, legend_pos_r + max_tick_arrow * 1.05, z_pos, ...
                         sprintf('%.1e', tick_val), ...
                         'Color', 'r', 'FontSize', 16, 'Interpreter', 'latex', ...
                         'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left');
                end
            end
        end

        dcm_obj = datacursormode(gcf);
        set(dcm_obj, 'UpdateFcn', {@myDataCursorUpdateFcn_PotentialExBPhysical, rc_core, zc_core, ...
                                   potential_core, vexb_pol_core, vexb_rad_core});

        saveFigureWithTimestamp(gcf, sprintf('Potential_ExB_Flow_Pattern_Physical_CellFlat_%s', ...
            createSafeFilename(dirName)));
        hold(ax, 'off');
    end

    fprintf('Potential & ExB flow pattern (physical grid, cell-flat) plotting completed.\n');
end

function [X_patch, Y_patch, C_patch] = buildCellFlatPatch(crx_core, cry_core, potential_core)
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
            C_patch(:, cell_idx) = potential_core(ix, iy);
        end
    end
end

function ticks = exbLegendTicks(max_exb_val)
    if max_exb_val <= 0 || ~isfinite(max_exb_val)
        ticks = [];
        return;
    end
    base_ticks = [1, 0.5, 0.1] * max_exb_val;
    ticks = unique(base_ticks(base_ticks > 0));
end

function output_txt = myDataCursorUpdateFcn_PotentialExBPhysical(~, event_obj, rc_core, zc_core, potential_core, vexb_pol_core, vexb_rad_core)
    pos = event_obj.Position;
    R = pos(1);
    Z = pos(2);

    distance_sq = (rc_core - R).^2 + (zc_core - Z).^2;
    [~, linear_idx] = min(distance_sq(:));
    [ix, iy] = ind2sub(size(distance_sq), linear_idx);

    potential_val = potential_core(ix, iy);
    vexb_pol_val = vexb_pol_core(ix, iy);
    vexb_rad_val = vexb_rad_core(ix, iy);
    vexb_mag = sqrt(vexb_pol_val^2 + vexb_rad_val^2);

    output_txt = {
        sprintf('R = %.4f m', R);
        sprintf('Z = %.4f m', Z);
        sprintf('i_x = %d', ix + 1);
        sprintf('i_y = %d', iy + 1);
        sprintf('\\phi = %.3e V', potential_val);
        sprintf('v_{ExB,pol} = %.3e m/s', vexb_pol_val);
        sprintf('v_{ExB,rad} = %.3e m/s', vexb_rad_val);
        sprintf('|v_{ExB}| = %.3e m/s', vexb_mag)
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

function drawEnhancedArrows(ax, X, Y, U, V, color, linewidth)
% DRAWENHANCEDARROWS 绘制增强型箭头，箭头帽更清晰明显
%   ax - 目标坐标轴
%   X, Y - 箭头起点坐标矩阵
%   U, V - 箭头方向和长度矩阵
%   color - 箭头颜色
%   linewidth - 箭头线宽
%
%   此函数使用patch绘制三角形箭头帽，比quiver的箭头更清晰

    if nargin < 6
        color = 'k';
    end
    if nargin < 7
        linewidth = 1.5;
    end

    % 箭头帽参数
    head_length_ratio = 0.25;  % 箭头帽长度占总长度的比例
    head_width_ratio = 0.15;   % 箭头帽宽度相对于长度的比例

    % 展平矩阵
    X = X(:);
    Y = Y(:);
    U = U(:);
    V = V(:);

    % 过滤零长度箭头
    arrow_length = sqrt(U.^2 + V.^2);
    valid_idx = arrow_length > 0;

    X = X(valid_idx);
    Y = Y(valid_idx);
    U = U(valid_idx);
    V = V(valid_idx);
    arrow_length = arrow_length(valid_idx);

    % 归一化方向
    U_norm = U ./ arrow_length;
    V_norm = V ./ arrow_length;

    % 垂直方向（用于箭头帽的宽度）
    U_perp = -V_norm;
    V_perp = U_norm;

    % 绘制每个箭头
    for i = 1:length(X)
        x0 = X(i);
        y0 = Y(i);
        u = U(i);
        v = V(i);
        len = arrow_length(i);

        % 箭头终点
        x1 = x0 + u;
        y1 = y0 + v;

        % 箭头帽尺寸
        head_len = len * head_length_ratio;
        head_width = len * head_width_ratio;

        % 箭头杆终点（箭头帽起点）
        shaft_end_x = x0 + u * (1 - head_length_ratio);
        shaft_end_y = y0 + v * (1 - head_length_ratio);

        % 绘制箭头杆
        line(ax, [x0, shaft_end_x], [y0, shaft_end_y], ...
             'Color', color, 'LineWidth', linewidth);

        % 箭头帽三角形的三个顶点
        % 顶点1：箭头尖端
        tip_x = x1;
        tip_y = y1;

        % 顶点2和3：箭头帽底部两侧
        base_x = shaft_end_x;
        base_y = shaft_end_y;

        perp_x = U_perp(i) * head_width;
        perp_y = V_perp(i) * head_width;

        vertex2_x = base_x + perp_x;
        vertex2_y = base_y + perp_y;
        vertex3_x = base_x - perp_x;
        vertex3_y = base_y - perp_y;

        % 绘制箭头帽（填充三角形）
        patch(ax, [tip_x, vertex2_x, vertex3_x], [tip_y, vertex2_y, vertex3_y], ...
              color, 'EdgeColor', color, 'LineWidth', linewidth*0.5);
    end
end
