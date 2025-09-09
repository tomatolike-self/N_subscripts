function plot_N_ExB_drift_flow_pattern(all_radiationData)
% PLOT_N_EXB_DRIFT_FLOW_PATTERN 绘制N离子ExB漂移通量密度分布图
%
%   此函数为每个提供的SOLPS算例数据，可以选择绘制：
%   1) 所有N离子价态（N1+到N7+）的ExB漂移通量密度总和
%   2) 特定价态的ExB漂移通量密度分布
%   它会显示一个背景色图，表示ExB漂移通量密度的大小，并在每个网格单元上
%   叠加箭头以指示通量的方向。
%
%   参数:
%     all_radiationData - 包含所有SOLPS仿真数据的结构体数组，
%                         每个结构体至少需要包含 'dirName', 'gmtry', 'plasma' 字段。

    % --- 全局字体和绘图属性设置 ---
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', 36); set(0, 'DefaultTextFontSize', 36);
    set(0, 'DefaultLineLineWidth', 1.5);
    set(0, 'DefaultUicontrolFontName', 'Times New Roman');
    set(0, 'DefaultUitableFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontSize', 32);
    set(0, 'DefaultTextInterpreter', 'latex');
    set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
    set(0, 'DefaultLegendInterpreter', 'latex');
    set(0, 'DefaultColorbarTickLabelInterpreter', 'latex');

    % --- 用户选择绘制模式 ---
    fprintf('\n=== N ExB Drift Flux Density Plotting Options ===\n');
    fprintf('0: Total flux density (sum of all N charge states)\n');
    fprintf('1-7: Specific charge state (N1+ to N7+)\n');
    charge_state_choice = input('Select charge state to plot (0 for total, 1-7 for specific): ');

    % 验证输入
    if isempty(charge_state_choice) || ~isnumeric(charge_state_choice) || isnan(charge_state_choice) || charge_state_choice < 0 || charge_state_choice > 7 || mod(charge_state_choice, 1) ~= 0
        fprintf('Invalid input. Using default: total flux density (0)\n');
        charge_state_choice = 0;
    end

    if charge_state_choice == 0
        fprintf('Selected: Total N ExB drift flux density (all charge states)\n');
        plot_mode = 'total';
        plot_title_prefix = 'Total N';
        species_description = 'all N charge states';
    else
        fprintf('Selected: N%d+ ExB drift flux density\n', charge_state_choice);
        plot_mode = 'specific';
        plot_title_prefix = sprintf('N%d+', charge_state_choice);
        species_description = sprintf('N%d+', charge_state_choice);
        target_species_idx = charge_state_choice + 3; % N1+ 对应 species index 4
    end

    for i_case = 1:length(all_radiationData)
        radData = all_radiationData{i_case};
        gmtry  = radData.gmtry; plasma = radData.plasma; dirName = radData.dirName;
        fprintf('Processing case for %s ExB drift flux density: %s\n', species_description, dirName);

        % --- 必要字段检查 ---
        if ~isfield(plasma,'vaecrb')
            warning('Case %s: plasma.vaecrb field not found. Skipping.', dirName); continue; end
        if ~isfield(plasma,'na')
            warning('Case %s: plasma.na field not found. Skipping.', dirName); continue; end

        if isfield(plasma,'veecrb')
            fprintf('Info: Case %s - plasma.veecrb field exists.\n', dirName);
        else
            fprintf('Info: Case %s - plasma.veecrb field NOT found.\n', dirName);
        end

        % --- 检查不同价态vaecrb一致性 (简化保留) ---
        fprintf('Info: Checking if vaecrb is the same across different N charge states...\n');
        min_species_idx_chk = 4; max_species_idx_chk = min(10, size(plasma.vaecrb,4));
        if max_species_idx_chk >= min_species_idx_chk+1
            v1 = plasma.vaecrb(:,:,:,min_species_idx_chk); v2 = plasma.vaecrb(:,:,:,min_species_idx_chk+1);
            max_diff_pol = max(abs(v1(:,:,1)-v2(:,:,1)),[],'all'); max_diff_rad = max(abs(v1(:,:,2)-v2(:,:,2)),[],'all');
            max_val_pol  = max(abs(v1(:,:,1)),[],'all'); max_val_rad  = max(abs(v1(:,:,2)),[],'all');
            rel_diff_pol = (max_val_pol>0)*max_diff_pol/max(max_val_pol,eps);
            rel_diff_rad = (max_val_rad>0)*max_diff_rad/max(max_val_rad,eps);
            fprintf('Info: vaecrb comparison N%d+ vs N%d+ Pol diff %.3e (rel %.3e), Rad diff %.3e (rel %.3e)\n',...
                min_species_idx_chk-3,min_species_idx_chk-2,max_diff_pol,rel_diff_pol,max_diff_rad,rel_diff_rad);
        else
            fprintf('Info: Not enough charge states for vaecrb comparison.\n');
        end

        % --- 网格维度 ---
        if isfield(gmtry,'crx'); s=size(gmtry.crx); nx_orig=s(1); ny_orig=s(2); elseif isfield(gmtry,'cry'); s=size(gmtry.cry); nx_orig=s(1); ny_orig=s(2); else
            warning('Grid coordinate fields missing for case %s. Skipping.', dirName); continue; end
        if nx_orig<3 || ny_orig<3
            warning('Original grid too small (%d,%d) - %s', nx_orig, ny_orig, dirName); continue; end
        nx_plot = nx_orig-2; ny_plot = ny_orig-2; fprintf('Info: Plot grid (no guard): %d x %d\n', nx_plot, ny_plot);
        if nx_plot<=0 || ny_plot<=0, warning('Non-positive plotting grid. Skipping %s', dirName); continue; end

        % --- 计算ExB通量密度 (总和或特定价态) ---
        if strcmp(plot_mode, 'total')
            % 累加所有N价态的ExB通量密度
            min_species_idx = 4; max_species_idx = min(10, size(plasma.vaecrb,4));
            total_flux_pol_plot = zeros(nx_plot, ny_plot); total_flux_rad_plot = zeros(nx_plot, ny_plot); valid_species_count=0;
            fprintf('  Summing ExB flux density for N charge states %d+ to %d+\n', min_species_idx-3, max_species_idx-3);
            for isp = min_species_idx:max_species_idx
                charge_state = isp-3;
                if size(plasma.na,3) < isp
                    fprintf('    Warning: Species %d (N%d+) missing in plasma.na (max %d).\n', isp, charge_state, size(plasma.na,3)); continue; end
                if size(plasma.vaecrb,4) < isp
                    fprintf('    Warning: Species %d (N%d+) missing in plasma.vaecrb (max %d).\n', isp, charge_state, size(plasma.vaecrb,4)); continue; end
                vexb_pol_full = plasma.vaecrb(:,:,1,isp); vexb_rad_full = plasma.vaecrb(:,:,2,isp);
                ion_density_full = plasma.na(:,:,isp);
                vexb_pol_plot = vexb_pol_full(2:nx_orig-1, 2:ny_orig-1);
                vexb_rad_plot = vexb_rad_full(2:nx_orig-1, 2:ny_orig-1);
                ion_density_plot = ion_density_full(2:nx_orig-1, 2:ny_orig-1);
                total_flux_pol_plot = total_flux_pol_plot + ion_density_plot .* vexb_pol_plot;
                total_flux_rad_plot = total_flux_rad_plot + ion_density_plot .* vexb_rad_plot;
                valid_species_count = valid_species_count + 1; fprintf('    Added N%d+\n', charge_state);
            end
            if valid_species_count==0
                warning('Case %s: No valid N species for ExB flux density. Skipping.', dirName); continue; end
            fprintf('  Total of %d N charge states included.\n', valid_species_count);
        else
            % 计算特定价态的ExB通量密度
            isp = target_species_idx;
            fprintf('  Calculating ExB flux density for N%d+ (species index %d)\n', charge_state_choice, isp);
            if size(plasma.na,3) < isp
                warning('Case %s: Species %d (N%d+) missing in plasma.na (max %d). Skipping.', dirName, isp, charge_state_choice, size(plasma.na,3)); continue; end
            if size(plasma.vaecrb,4) < isp
                warning('Case %s: Species %d (N%d+) missing in plasma.vaecrb (max %d). Skipping.', dirName, isp, charge_state_choice, size(plasma.vaecrb,4)); continue; end
            vexb_pol_full = plasma.vaecrb(:,:,1,isp); vexb_rad_full = plasma.vaecrb(:,:,2,isp);
            ion_density_full = plasma.na(:,:,isp);
            vexb_pol_plot = vexb_pol_full(2:nx_orig-1, 2:ny_orig-1);
            vexb_rad_plot = vexb_rad_full(2:nx_orig-1, 2:ny_orig-1);
            ion_density_plot = ion_density_full(2:nx_orig-1, 2:ny_orig-1);
            total_flux_pol_plot = ion_density_plot .* vexb_pol_plot;
            total_flux_rad_plot = ion_density_plot .* vexb_rad_plot;
            fprintf('  N%d+ ExB flux density calculated.\n', charge_state_choice);
        end

        % --- 总通量大小与归一化方向 ---
        total_flux_magnitude_plot = sqrt(total_flux_pol_plot.^2 + total_flux_rad_plot.^2);
        u_norm_plot = zeros(size(total_flux_pol_plot)); v_norm_plot = zeros(size(total_flux_rad_plot));
        nz = total_flux_magnitude_plot > 1e-15; u_norm_plot(nz)=total_flux_pol_plot(nz)./total_flux_magnitude_plot(nz); v_norm_plot(nz)=total_flux_rad_plot(nz)./total_flux_magnitude_plot(nz);

        % ================== 统一计算网格绘制方式 (参考 plot_flow_pattern_computational_grid) ==================
        fig_title_name = sprintf('%s ExB Drift Flux Density - Comp. Grid (no guard) - %s', plot_title_prefix, dirName);
        fig = figure('Name', fig_title_name, 'NumberTitle','off','Color','w','Units','inches','Position',[1 1 10 7]);
        ax = axes(fig); hold(ax,'on');

        % 为log色标避免0或负值
        min_positive = min(total_flux_magnitude_plot(total_flux_magnitude_plot>0),[],'all');
        if isempty(min_positive); min_positive = 1; end
        flux_display = total_flux_magnitude_plot; flux_display(flux_display<=0) = 0.1*min_positive;

        % 背景着色 (单元中心 imagesc) —— 单元中心: 1,2,...,nx_plot
        imagesc(ax, 1:nx_plot, 1:ny_plot, flux_display');
        set(ax,'XLim',[0.5 nx_plot+0.5],'YLim',[0.5 ny_plot+0.5],'YDir','normal');
        shading(ax,'flat');
        h_cb = colorbar(ax); set(ax,'ColorScale','log');
        ylabel(h_cb, [plot_title_prefix ' ExB Drift Flux Density (m$^{-2}$s$^{-1}$)'], 'FontSize', 32, 'Interpreter', 'latex');
        colormap(ax,'jet');

        % 数据游标 (单元中心)
        dcm_obj = datacursormode(fig); set(dcm_obj,'Enable','on');
        set(dcm_obj,'UpdateFcn',{ @myDataCursorUpdateFcn_ExB_Total_Flux_CellCentered, nx_plot, ny_plot, total_flux_pol_plot, total_flux_rad_plot, total_flux_magnitude_plot});

        % 箭头 (单元中心坐标)
        if nx_plot>1 && ny_plot>1
            arrow_scale = 0.4; x_centers = 1:nx_plot; y_centers = 1:ny_plot; [Xq,Yq] = meshgrid(x_centers, y_centers);
            if size(u_norm_plot,1)==nx_plot && size(u_norm_plot,2)==ny_plot
                uq = u_norm_plot'; vq = v_norm_plot';
            elseif size(u_norm_plot,1)==ny_plot && size(u_norm_plot,2)==nx_plot
                uq = u_norm_plot; vq = v_norm_plot; % 已经转置过
            else
                error('Normalized flux arrays dimension mismatch.');
            end
            quiver(ax, Xq, Yq, uq, vq, arrow_scale,'k','LineWidth',0.6);
        else
            fprintf('Info: Not enough cells for arrows (%d,%d).\n', nx_plot, ny_plot);
        end

        % 区域边界与标签 —— 使用统一常量
        C = getGridRegionConstants();
        isep_idx = C.separatrix_line; inner_div_end=C.inner_div_end; omp_idx=C.omp_idx; imp_idx=C.imp_idx; outer_div_start=C.outer_div_start;
        % 分隔线 (位于单元边界 => index + 0.5)
        plot(ax,[inner_div_end+0.5 inner_div_end+0.5],[0.5 ny_plot+0.5],'k--','LineWidth',1.0);
        plot(ax,[outer_div_start-0.5 outer_div_start-0.5],[0.5 ny_plot+0.5],'k--','LineWidth',1.0);
        plot(ax,[omp_idx+0.5 omp_idx+0.5],[0.5 ny_plot+0.5],'k--','LineWidth',1.0);
        plot(ax,[imp_idx+0.5 imp_idx+0.5],[0.5 ny_plot+0.5],'k--','LineWidth',1.0);
        plot(ax,[0.5 nx_plot+0.5],[isep_idx+0.5 isep_idx+0.5],'k-','LineWidth',1.5);

        % 顶部标签位置
        label_font_size=32; top_label_y_pos = ny_plot + 1.2;
        text(ax,1,top_label_y_pos,'OT','FontSize',label_font_size,'HorizontalAlignment','center','FontWeight','bold');
        text(ax,inner_div_end,top_label_y_pos,'ODE','FontSize',label_font_size,'HorizontalAlignment','center','FontWeight','bold');
        text(ax,omp_idx,top_label_y_pos,'OMP','FontSize',label_font_size,'HorizontalAlignment','center','FontWeight','bold');
        text(ax,imp_idx,top_label_y_pos,'IMP','FontSize',label_font_size,'HorizontalAlignment','center','FontWeight','bold');
        text(ax,outer_div_start,top_label_y_pos,'IDE','FontSize',label_font_size,'HorizontalAlignment','center','FontWeight','bold');
        text(ax,nx_plot,top_label_y_pos,'IT','FontSize',label_font_size,'HorizontalAlignment','center','FontWeight','bold');

        % Core / SOL / PFR 标签
        core_sol_x_pos = round(nx_plot/2); core_y_pos = round(isep_idx*0.6); sol_y_pos = isep_idx + round((ny_plot - isep_idx)*0.65);
        text(ax, core_sol_x_pos, core_y_pos, 'Core','FontSize',label_font_size,'HorizontalAlignment','center','VerticalAlignment','middle','FontWeight','bold');
        text(ax, core_sol_x_pos, sol_y_pos, 'SOL','FontSize',label_font_size,'HorizontalAlignment','center','VerticalAlignment','middle','FontWeight','bold');
        PFR_x_left = round(inner_div_end*0.5); PFR_x_right = round(outer_div_start + (nx_plot - outer_div_start)*0.5);
        text(ax, PFR_x_left, core_y_pos, 'PFR','FontSize',label_font_size,'HorizontalAlignment','center','VerticalAlignment','middle','FontWeight','bold');
        text(ax, PFR_x_right, core_y_pos, 'PFR','FontSize',label_font_size,'HorizontalAlignment','center','VerticalAlignment','middle','FontWeight','bold');
        text(ax, core_sol_x_pos, isep_idx+2, 'Separatrix','FontSize',label_font_size,'HorizontalAlignment','center','FontWeight','bold');

        % 坐标轴 & 刻度
        xlabel(ax,'$i_x$ (Poloidal Cell Index)','FontSize',34,'Interpreter','latex');
        ylabel(ax,'$i_y$ (Radial Cell Index)','FontSize',34,'Interpreter','latex');
        axis(ax,[0.5 nx_plot+0.5 0.5 ny_plot+0.5]);
        xticks_unique = unique([1 inner_div_end omp_idx imp_idx outer_div_start nx_plot]); yticks_unique = unique([1 isep_idx ny_plot]);
        set(ax,'XTick',xticks_unique,'YTick',yticks_unique,'FontSize',28);
        box(ax,'on'); grid(ax,'off'); hold(ax,'off');

        % 保存
        if strcmp(plot_mode, 'total')
            filename_base = sprintf('ExB_Drift_TotalFluxDensity_N_CompGrid_NoGuard_%s', createSafeFilename(dirName));
        else
            filename_base = sprintf('ExB_Drift_FluxDensity_N%d_CompGrid_NoGuard_%s', charge_state_choice, createSafeFilename(dirName));
        end
        saveFigureWithTimestamp(fig, filename_base);
    end
end

% ================= 附属函数 =================
function C = getGridRegionConstants()
    C.inner_div_end    = 24;   % ODE末端(单元中心索引)
    C.outer_div_start  = 73;   % IDE起始(单元中心索引)
    C.separatrix_line  = 12;   % 分离面位于 12 与 13 之间 -> 线画在 12.5
    C.omp_idx          = 41;   % OMP
    C.imp_idx          = 58;   % IMP
end

function safeName = createSafeFilename(originalName)
    safeName = regexprep(originalName, '[^a-zA-Z0-9_\-\.]', '_');
    if strlength(safeName) > 100; safeName = safeName(1:100); end
end

function saveFigureWithTimestamp(figHandle, baseName)
    set(figHandle,'PaperPositionMode','auto');
    timestampStr = datestr(now,'yyyymmdd_HHMMSS');
    figFile = sprintf('%s_%s.fig', baseName, timestampStr);
    try; savefig(figHandle, figFile); fprintf('MATLAB figure saved to: %s\n', figFile); catch ME_fig; fprintf('Warning: Failed to save .fig file. Error: %s\n', ME_fig.message); end
end

function output_txt = myDataCursorUpdateFcn_ExB_Total_Flux_CellCentered(~, event_obj, nx_p, ny_p, total_flux_pol_data, total_flux_rad_data, total_flux_mag_data)
% 数据游标：采用单元中心坐标 (1..nx, 1..ny)
    pos = get(event_obj,'Position'); x_clicked = pos(1); y_clicked = pos(2);
    if nx_p>1 && ny_p>1
        x_centers = 1:nx_p; y_centers = 1:ny_p; [~, ix] = min(abs(x_centers - x_clicked)); [~, iy] = min(abs(y_centers - y_clicked));
        pol_val = total_flux_pol_data(ix,iy); rad_val = total_flux_rad_data(ix,iy); mag_val = total_flux_mag_data(ix,iy);
        output_txt = {sprintf('Cell (ix, iy): (%d, %d)', ix, iy), ...
                      sprintf('  Poloidal Flux Density: %.3e m^{-2}s^{-1}', pol_val), ...
                      sprintf('  Radial Flux Density: %.3e m^{-2}s^{-1}', rad_val), ...
                      sprintf('  Magnitude: %.3e m^{-2}s^{-1}', mag_val)};
    else
        ix = max(1,min(round(x_clicked),nx_p)); iy = max(1,min(round(y_clicked),ny_p)); mag_val = total_flux_mag_data(ix,iy);
        output_txt = {sprintf('Cell (ix,iy) = (%d,%d)',ix,iy), sprintf('  Magnitude: %.3e m^{-2}s^{-1}', mag_val)};
    end
end
