function plot_downstream_pol_profiles(all_radiationData, groupDirs, varargin)
    % =========================================================================
    % 功能：
    %   按"组"为单位绘制下游靶板附近的电子密度、电子温度、杂质密度和极向热流密度的极向分布子图，
    %   用于多算例对比。每个 group 生成两个 figure：
    %   - Figure 1: 内外靶板的电子密度和电子温度 (2×2 布局)
    %   - Figure 2: 内外靶板的杂质密度和极向热流密度分布 (2×2 布局)
    %
    % 输入：
    %   all_radiationData : cell 数组，每个元素包含:
    %       .dirName  (string)  => 当前算例的全路径/标识
    %       .gmtry    (struct)  => 包含 crx/cry/hx/hy/vol 等网格信息
    %       .plasma   (struct)  => 包含 ne, te_ev, ti_ev 等等
    %       .plasma.fhi_mdf  (3D array)=> 离子热流密度 (需要(:,:,1) for poloidal)
    %       .plasma.fhe_mdf  (3D array)=> 电子热流密度 (需要(:,:,1) for poloidal)
    %       ... 还有你需要用到的其他字段
    %
    %   groupDirs : cell 数组 => { Group1Dirs, Group2Dirs, ... }
    %       例如，groupDirs{1} = { 'path/to/caseA', 'path/to/caseB', ... }
    %       代表第 1 组包含若干目录
    %
    %   varargin: 可选参数，用于设置图例类型
    %       'usePredefinedLegend', true 或 false (默认: false)
    %           true:  使用预定义的图例名称，顺序对应目录顺序
    %                  预定义名称为: 'favorable B_T', 'unfavorable B_T', 'w/o drift'
    %           false (默认): 使用目录名作为图例
    %
    % 输出：
    %   本函数无显式返回值，但会在屏幕上显示并保存一系列图形 (.fig) 文件：
    %     - 每个 group 对应 2 个 figure
    %     - Figure 1: 电子密度和电子温度 (2×2 布局)
    %     - Figure 2: 杂质密度和极向热流密度 (2×2 布局)
    %     - 不同算例曲线叠加对比
    %
    % 说明：
    %   1) 绘制下游两个靶板附近的电子密度、电子温度、杂质密度和极向热流密度径向分布
    %   2) 杂质密度统计仅包含离子态杂质（N1+到N7+），不包含中性杂质粒子
    %   3) 极向热流密度计算方式：(fhi_mdf(:,:,1) + fhe_mdf(:,:,1)) ./ (gmtry.gs(:,:,1) .* gmtry.qz(:,:,2))
    %   4) 横坐标使用物理坐标(相对于分离面 x=0)
    %   5) 若要对组或目录进行颜色/marker 区分，可在下方预先定义。
    %
    % 作者：XXX
    % 日期：2025-01-23
    % 修改：2025-01-24  添加可选的预定义图例名称
    %       2025-01-25  简化图例类型参数为 usePredefinedLegend (boolean)
    %       2025-01-26  修改为绘制极向热流密度，并考虑外靶板热流方向
    %       2025-01-27  修改为两个figure，增大默认尺寸，添加极向热流密度

    % ========== 处理可选输入参数 ==========
    p = inputParser;
    addParameter(p, 'usePredefinedLegend', false, @islogical); % 修改为布尔标志
    parse(p, varargin{:});
    usePredefinedLegend = p.Results.usePredefinedLegend; % 获取布尔值

    % ========== 预定义一些绘图风格 ==========
    % 设置标准学术作图规范
    fontName = 'Times New Roman';  % 使用Times New Roman字体
    xlabelsize = 24;  % 增大标签字体大小
    ylabelsize = 24;  % 增大标签字体大小
    titlesize  = 24;  % 增大标题字体大小
    legendsize = 22;  % 图例字体大小
    
    % 设置默认字体
    set(0, 'DefaultAxesFontName', fontName);
    set(0, 'DefaultTextFontName', fontName);
    set(0, 'DefaultAxesFontSize', xlabelsize);
    set(0, 'DefaultTextFontSize', xlabelsize);
    
    % 设置坐标轴线宽和框线风格，符合学术论文标准
    set(0, 'DefaultAxesLineWidth', 1.5);
    set(0, 'DefaultAxesBox', 'on');

    % 颜色和 marker，可按需要增减
    line_colors = lines(20);
    % 去掉markers列表，不再使用形状标记
    % line_markers = {'o','s','d','^','v','>','<','p','h','*','+','x'};
    
    % 设置线宽，使线条在打印出来时更加明显
    linewidth = 3.0;  % 增加线宽，使图形在论文中更加清晰

    % ========== 网格与索引定义 ==========
    % 网格说明：
    % - 原始网格（包含保护单元）：98×28
    % - 裁剪网格（去除保护单元）：96×26，对应原始网格(2:97, 2:27)
    % - 内靶板：原始网格97号 → 裁剪网格96号
    % - 外靶板：原始网格2号 → 裁剪网格1号
    % - 分离面：位于裁剪网格12和13之间，即第12个网格的末端边界
    separatrix_radial_index = 12;  % 分离面所在的网格索引（裁剪网格中的径向索引）
    outer_target_j_index = 1;      % 外靶板在裁剪网格中的极向索引（对应原始网格2号）
    inner_target_j_index = 96;     % 内靶板在裁剪网格中的极向索引（对应原始网格97号）

    % ========== 遍历各组，每组输出 1 个 figure ==========
    num_groups = length(groupDirs);

    for g = 1 : num_groups

        % 取出第 g 组的目录列表
        currentGroup = groupDirs{g};

        % === 新建第一个 figure (针对第 g 组) - 电子密度和电子温度 ===
        figTitle1 = sprintf('Group %d: Target ne & Te Profiles', g);
        fig1 = figure('Name', figTitle1, 'NumberTitle', 'off', 'Color','w', ...
                     'Units', 'inches', 'Position', [1 1 14 10]);  % 放大默认尺寸

        % 先获取第一个figure的 subplot 句柄 (2×2 布局)
        ax1  = subplot(2,2,1); hold(ax1,'on'); % Inner Target, ne
        ax2  = subplot(2,2,2); hold(ax2,'on'); % Outer Target, ne
        ax3  = subplot(2,2,3); hold(ax3,'on'); % Inner Target, te
        ax4  = subplot(2,2,4); hold(ax4,'on'); % Outer Target, te

        % 强制设置第一个figure子图的大小和位置
        % Position格式: [left bottom width height]，值范围0-1（归一化坐标）
        set(ax1, 'Position', [0.08 0.55 0.38 0.35]); % 左上
        set(ax2, 'Position', [0.55 0.55 0.38 0.35]); % 右上
        set(ax3, 'Position', [0.08 0.10 0.38 0.35]); % 左下
        set(ax4, 'Position', [0.55 0.10 0.38 0.35]); % 右下

        % 设置第一个figure所有子图的坐标轴属性
        axList1 = [ax1, ax2, ax3, ax4];
        for ax = axList1
            set(ax, 'LineWidth', 1.5);
            set(ax, 'Box', 'on');
            set(ax, 'TickDir', 'in');  % 刻度线指向内部
            grid(ax, 'on');
            set(ax, 'GridLineStyle', ':');
            set(ax, 'GridAlpha', 0.25);
        end

        % === 新建第二个 figure (针对第 g 组) - 杂质密度和极向热流密度 ===
        figTitle2 = sprintf('Group %d: Target Impurity & Poloidal Heat Flux Profiles', g);
        fig2 = figure('Name', figTitle2, 'NumberTitle', 'off', 'Color','w', ...
                     'Units', 'inches', 'Position', [16 1 14 10]);  % 放大默认尺寸，位置偏移

        % 先获取第二个figure的 subplot 句柄 (2×2 布局)
        ax5  = subplot(2,2,1); hold(ax5,'on'); % Inner Target, impurity density
        ax6  = subplot(2,2,2); hold(ax6,'on'); % Outer Target, impurity density
        ax7  = subplot(2,2,3); hold(ax7,'on'); % Inner Target, poloidal heat flux density
        ax8  = subplot(2,2,4); hold(ax8,'on'); % Outer Target, poloidal heat flux density

        % 强制设置第二个figure子图的大小和位置
        set(ax5, 'Position', [0.08 0.55 0.38 0.35]); % 左上
        set(ax6, 'Position', [0.55 0.55 0.38 0.35]); % 右上
        set(ax7, 'Position', [0.08 0.10 0.38 0.35]); % 左下
        set(ax8, 'Position', [0.55 0.10 0.38 0.35]); % 右下

        % 设置第二个figure所有子图的坐标轴属性
        axList2 = [ax5, ax6, ax7, ax8];
        for ax = axList2
            set(ax, 'LineWidth', 1.5);
            set(ax, 'Box', 'on');
            set(ax, 'TickDir', 'in');  % 刻度线指向内部
            grid(ax, 'on');
            set(ax, 'GridLineStyle', ':');
            set(ax, 'GridAlpha', 0.25);
        end

        % 初始化 legend 相关的 cell 数组 for each subplot
        ax1_handles = gobjects(0); ax1_legend_entries = {};
        ax2_handles = gobjects(0); ax2_legend_entries = {};
        ax3_handles = gobjects(0); ax3_legend_entries = {};
        ax4_handles = gobjects(0); ax4_legend_entries = {};
        ax5_handles = gobjects(0); ax5_legend_entries = {};
        ax6_handles = gobjects(0); ax6_legend_entries = {};
        ax7_handles = gobjects(0); ax7_legend_entries = {};
        ax8_handles = gobjects(0); ax8_legend_entries = {};

        % 预定义的图例名称
        predefined_legend_names = {'$\mathrm{fav.}~B_{\mathrm{T}}$', '$\mathrm{unfav.}~B_{\mathrm{T}}$', '$\mathrm{w/o~drift}$'};

        % ========== 遍历本组内的各算例目录 ==========
        for k = 1 : length(currentGroup)

            currentDir = currentGroup{k};
            % === 在 all_radiationData 中找到与 currentDir 匹配的记录 ===
            idx_in_all = findDirIndexInRadiationData(all_radiationData, currentDir);
            if idx_in_all < 0
                fprintf('Warning: directory %s not found in all_radiationData.\n', currentDir);
                continue;
            end

            dataStruct = all_radiationData{idx_in_all};
            if ~isfield(dataStruct,'plasma') || ~isfield(dataStruct,'gmtry')
                fprintf('Warning: dataStruct for %s missing .plasma or .gmtry\n', currentDir);
                continue;
            end

            gmtry  = dataStruct.gmtry;
            plasma = dataStruct.plasma;
            neut  = dataStruct.neut;
            fhi_mdf = plasma.fhi_mdf;
            fhe_mdf = plasma.fhe_mdf;
            dirName= dataStruct.dirName;  % 全路径

            % 生成 legend 名称
            if usePredefinedLegend % 使用布尔标志判断
                legend_index = mod(k-1, length(predefined_legend_names)) + 1; % 循环使用预定义名称
                simplifiedDirName = predefined_legend_names{legend_index};
            else % 默认情况: 使用 dirname
                simplifiedDirName = getShortDirName(dirName);
            end


            % 取网格大小
            [nxd, nyd] = size(gmtry.crx(:,:,1));

            % ========== 计算下游方向的物理坐标 (以分离面为 x=0) ==========

            % -- 1) 外靶板 (j=outer_target_j_index) --
            Y_down_outer_target = gmtry.hy(outer_target_j_index+1,2:end-1);  % +1因为gmtry包含保护单元
            W_down_outer_target = [0.5*Y_down_outer_target(1), 0.5*(Y_down_outer_target(2:end)+Y_down_outer_target(1:end-1))];
            hy_downstream_center_outer_target = cumsum(W_down_outer_target);
            % 分离面位置：第12个网格的末端位置（12号和13号网格的交界面）
            % 第12个网格的中心位置加上半个网格宽度
            separatrix_downstream_outer_target = hy_downstream_center_outer_target(separatrix_radial_index) + 0.5*Y_down_outer_target(separatrix_radial_index);
            x_downstream_outer_target = hy_downstream_center_outer_target - separatrix_downstream_outer_target;

            % -- 2) 内靶板 (j=inner_target_j_index) --
            Y_down_inner_target = gmtry.hy(inner_target_j_index+1,2:end-1);  % +1因为gmtry包含保护单元
            W_down_inner_target = [0.5*Y_down_inner_target(1), 0.5*(Y_down_inner_target(2:end)+Y_down_inner_target(1:end-1))];
            hy_downstream_center_inner_target = cumsum(W_down_inner_target);
            % 分离面位置：第12个网格的末端位置（12号和13号网格的交界面）
            % 第12个网格的中心位置加上半个网格宽度
            separatrix_downstream_inner_target = hy_downstream_center_inner_target(separatrix_radial_index) + 0.5*Y_down_inner_target(separatrix_radial_index);
            x_downstream_inner_target = hy_downstream_center_inner_target - separatrix_downstream_inner_target;


            % 检查 plasma 中必要字段
            if ~isfield(plasma, 'ne') || ~isfield(plasma, 'te_ev') || ~isfield(plasma, 'fhi_mdf') || ~isfield(plasma, 'fhe_mdf')
                fprintf('Missing fields in plasma: ne / te_ev / fhi_mdf / fhe_mdf.\n');
                continue;
            end
            if ~isfield(gmtry, 'gs') || ~isfield(gmtry, 'qz')
                fprintf('Missing fields in gmtry: gs / qz.\n');
                continue;
            end


            ne_2D = plasma.ne(2:end-1,2:end-1);
            te_2D = plasma.te_ev(2:end-1,2:end-1);

            % 计算极向热流密度 (参考 plot_total_heat_flux_density_computational_grid.m)
            % 极向热流密度 = 极向总热流 / 极向面积
            total_heat_pol_full = fhi_mdf(:,:,1) + fhe_mdf(:,:,1);  % 极向总热流 (W)
            area_pol_full = gmtry.gs(:,:,1) .* gmtry.qz(:,:,2);     % 极向通量对应的面积 (m^2)
            poloidal_heat_flux_density_full = total_heat_pol_full ./ area_pol_full;  % 极向热流密度 (W/m^2)
            poloidal_heat_flux_density_2D = poloidal_heat_flux_density_full(2:end-1,2:end-1);  % 去除保护单元

            % 计算杂质密度（仅包含离子态杂质）
            if isfield(plasma, 'na')
                % 计算杂质总密度（从N1+到N7+的总和，即第3维从4到10）
                % 不包含中性杂质粒子密度
                impurity_density_total = sum(plasma.na(2:end-1,2:end-1,4:10), 3);
            else
                fprintf('Warning: plasma.na field not found for impurity calculation in %s\n', dirName);
                impurity_density_total = zeros(size(ne_2D)); % 如果没有na字段，则用零矩阵代替
            end


            % ====== 分配颜色 / marker (与 k 对应) ======
            dir_color  = line_colors(mod(k-1,size(line_colors,1))+1,:);
            % 去掉marker，只使用颜色区分
            % 增加线宽以便更好区分
            plotStyle  = {'-','Color', dir_color, 'LineWidth',linewidth};

            % ================================================================
            % Figure 1: 电子密度和电子温度
            % ================================================================

            % ----------------------------------------------------------------
            % (1) Inner Target electron density (inner_target_j_index,:)
            % ----------------------------------------------------------------
            h1 = plot(ax1, x_downstream_inner_target, ne_2D(inner_target_j_index,:), plotStyle{:});
            set(h1, 'DisplayName', simplifiedDirName);
            set(h1, 'UserData', dirName);  % 用于 datacursor
            % 在分离面 x=0 画一条线
            plot(ax1, [0 0], ylim(ax1),'k--','LineWidth',1.2);
            xlabel(ax1,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
            ylabel(ax1,'$n_{\mathrm{e}}$ (m$^{-3}$)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
            ylim(ax1, [0 5e20]);  % 修改ne Y轴范围为0-5e20
            ax1_handles(end+1) = h1; ax1_legend_entries{end+1} = simplifiedDirName;

            % ----------------------------------------------------------------
            % (2) Outer Target electron density (outer_target_j_index,:)
            % ----------------------------------------------------------------
            h2 = plot(ax2, x_downstream_outer_target, ne_2D(outer_target_j_index,:), plotStyle{:});
            set(h2,'UserData', dirName);
            plot(ax2, [0 0], ylim(ax2),'k--','LineWidth',1.2);
            xlabel(ax2,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
            ylabel(ax2,'$n_{\mathrm{e}}$ (m$^{-3}$)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
            ylim(ax2, [0 5e20]);  % 修改ne Y轴范围为0-5e20
            ax2_handles(end+1) = h2; ax2_legend_entries{end+1} = simplifiedDirName;

            % ----------------------------------------------------------------
            % (3) Inner Target electron temperature (inner_target_j_index,:)
            % ----------------------------------------------------------------
            h3 = plot(ax3, x_downstream_inner_target, te_2D(inner_target_j_index,:), plotStyle{:});
            set(h3,'UserData', dirName);
            plot(ax3, [0 0], ylim(ax3),'k--','LineWidth',1.2);
            xlabel(ax3,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
            ylabel(ax3,'$T_{\mathrm{e}}$ (eV)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
            ylim(ax3, [0 25]);  % 设置Te Y轴范围为0-25 eV
            ax3_handles(end+1) = h3; ax3_legend_entries{end+1} = simplifiedDirName;

            % ----------------------------------------------------------------
            % (4) Outer Target electron temperature (outer_target_j_index,:)
            % ----------------------------------------------------------------
            h4 = plot(ax4, x_downstream_outer_target, te_2D(outer_target_j_index,:), plotStyle{:});
            set(h4,'UserData', dirName);
            plot(ax4, [0 0], ylim(ax4),'k--','LineWidth',1.2);
            xlabel(ax4,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
            ylabel(ax4,'$T_{\mathrm{e}}$ (eV)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
            ylim(ax4, [0 25]);  % 设置Te Y轴范围为0-25 eV
            ax4_handles(end+1) = h4; ax4_legend_entries{end+1} = simplifiedDirName;

            % ================================================================
            % Figure 2: 杂质密度和极向热流密度
            % ================================================================

            % ----------------------------------------------------------------
            % (5) Inner Target Impurity density (inner_target_j_index,:)
            % ----------------------------------------------------------------
            h5 = plot(ax5, x_downstream_inner_target, impurity_density_total(inner_target_j_index,:), plotStyle{:});
            set(h5,'UserData', dirName);
            plot(ax5, [0 0], ylim(ax5),'k--','LineWidth',1.2);
            xlabel(ax5,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
            ylabel(ax5,'$n_{\mathrm{imp}}$ (m$^{-3}$)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
            ylim(ax5, [0 6e19]);  % 修改nimp Y轴范围为0-5e19
            ax5_handles(end+1) = h5; ax5_legend_entries{end+1} = simplifiedDirName;

            % ----------------------------------------------------------------
            % (6) Outer Target Impurity density (outer_target_j_index,:)
            % ----------------------------------------------------------------
            h6 = plot(ax6, x_downstream_outer_target, impurity_density_total(outer_target_j_index,:), plotStyle{:});
            set(h6,'UserData', dirName);
            plot(ax6, [0 0], ylim(ax6),'k--','LineWidth',1.2);
            xlabel(ax6,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
            ylabel(ax6,'$n_{\mathrm{imp}}$ (m$^{-3}$)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
            ylim(ax6, [0 6e19]);  % 修改nimp Y轴范围为0-5e19
            ax6_handles(end+1) = h6; ax6_legend_entries{end+1} = simplifiedDirName;

            % ----------------------------------------------------------------
            % (7) Inner Target Poloidal Heat Flux Density (inner_target_j_index,:)
            % ----------------------------------------------------------------
            h7 = plot(ax7, x_downstream_inner_target, poloidal_heat_flux_density_2D(inner_target_j_index,:), plotStyle{:});
            set(h7,'UserData', dirName);
            plot(ax7, [0 0], ylim(ax7),'k--','LineWidth',1.2);
            xlabel(ax7,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
            ylabel(ax7,'$q_{\mathrm{pol}}$ (W/m$^{2}$)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
            ylim(ax7, [-2e6 2e6]); % 修改q Y轴范围为-2e6到2e6
            ax7_handles(end+1) = h7; ax7_legend_entries{end+1} = simplifiedDirName;

            % ----------------------------------------------------------------
            % (8) Outer Target Poloidal Heat Flux Density (outer_target_j_index,:)
            % ----------------------------------------------------------------
            h8 = plot(ax8, x_downstream_outer_target, poloidal_heat_flux_density_2D(outer_target_j_index,:), plotStyle{:});
            set(h8,'UserData', dirName);
            plot(ax8, [0 0], ylim(ax8),'k--','LineWidth',1.2);
            xlabel(ax8,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
            ylabel(ax8,'$q_{\mathrm{pol}}$ (W/m$^{2}$)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
            ylim(ax8, [-2e6 2e6]); % 修改q Y轴范围为-2e6到2e6
            ax8_handles(end+1) = h8; ax8_legend_entries{end+1} = simplifiedDirName;


        end % (end of each directory in group g)

        % ========== Figure 1: 电子密度和电子温度 ==========
        figure(fig1);  % 确保当前figure是第一个

        % 同步左右两侧的y轴范围
        linkaxes([ax1, ax2], 'y');  % 电子密度
        linkaxes([ax3, ax4], 'y');  % 电子温度

        % 在每个 subplot 上加 legend
        legend(ax1, ax1_handles, ax1_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);
        legend(ax2, ax2_handles, ax2_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);
        legend(ax3, ax3_handles, ax3_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);
        legend(ax4, ax4_handles, ax4_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);

        % 增强所有坐标轴刻度字体
        set(ax1, 'FontName', fontName, 'FontSize', xlabelsize);
        set(ax2, 'FontName', fontName, 'FontSize', xlabelsize);
        set(ax3, 'FontName', fontName, 'FontSize', xlabelsize);
        set(ax4, 'FontName', fontName, 'FontSize', xlabelsize);

        % Data Cursor mode for Figure 1
        dcm1 = datacursormode(fig1);
        set(dcm1,'UpdateFcn',@myDataCursorUpdateFcn);

        % 保存第一个图
        saveFigureWithTimestamp(sprintf('target_ne_te_profiles_group%d', g));

        % ========== Figure 2: 杂质密度和极向热流密度 ==========
        figure(fig2);  % 确保当前figure是第二个

        % 同步左右两侧的y轴范围
        linkaxes([ax5, ax6], 'y');  % 杂质密度
        linkaxes([ax7, ax8], 'y');  % 极向热流密度

        % 在每个 subplot 上加 legend
        legend(ax5, ax5_handles, ax5_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);
        legend(ax6, ax6_handles, ax6_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);
        legend(ax7, ax7_handles, ax7_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);
        legend(ax8, ax8_handles, ax8_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);

        % 增强所有坐标轴刻度字体
        set(ax5, 'FontName', fontName, 'FontSize', xlabelsize);
        set(ax6, 'FontName', fontName, 'FontSize', xlabelsize);
        set(ax7, 'FontName', fontName, 'FontSize', xlabelsize);
        set(ax8, 'FontName', fontName, 'FontSize', xlabelsize);

        % Data Cursor mode for Figure 2
        dcm2 = datacursormode(fig2);
        set(dcm2,'UpdateFcn',@myDataCursorUpdateFcn);

        % 保存第二个图
        saveFigureWithTimestamp(sprintf('target_impurity_poloidal_heatflux_profiles_group%d', g));

        fprintf('>>> Finished group %d (Target Profiles) with %d directories.\n', g, length(currentGroup));
        fprintf('    - Figure 1: Electron density and temperature profiles\n');
        fprintf('    - Figure 2: Impurity density and poloidal heat flux density profiles\n');

    end % (end for each group)

    fprintf('\nAll groups of target profiles have been plotted in separate figures.\n');
    fprintf('Each group generates 2 figures:\n');
    fprintf('  - Figure 1: Electron density and temperature profiles (ne, Te)\n');
    fprintf('  - Figure 2: Impurity density and poloidal heat flux density profiles (n_imp, q_pol)\n');
    fprintf('Note: In each figure, left column shows Inner Target profiles, right column shows Outer Target profiles.\n');

end % end of function main


%% ========== 子函数：找出 dirName 在 all_radiationData 中的索引 (与原脚本相同) ==========
function idx = findDirIndexInRadiationData(all_radiationData, dirName)
    idx = -1;
    for i = 1 : length(all_radiationData)
        thisDir = all_radiationData{i}.dirName;
        % 简单判断是否字符串相等即可(也可用 strcmpi)
        if strcmp(thisDir, dirName)
            idx = i;
            return;
        end
    end
end


%% ========== 子函数：取简短目录名 (与原脚本相同) ==========
function shortName = getShortDirName(fullPath)
    % 这里可与 generate_simplified_dir_name() 类似
    % 简化一下：只取最后一级目录
    parts = strsplit(fullPath, filesep);
    shortName = parts{end};
    % 如果需要更进一步的精简，可再处理
end


%% ========== 子函数：DataCursor 回调示例 (与原脚本相同) ==========
function txt = myDataCursorUpdateFcn(~, event_obj)
    pos = get(event_obj,'Position');
    target = get(event_obj,'Target');
    dirPath = get(target,'UserData');
    if ~isempty(dirPath)
        txt = {
            ['X: ', num2str(pos(1))],...
            ['Y: ', num2str(pos(2))],...
            ['Dir: ', dirPath]
        };
    else
        txt = {
            ['X: ', num2str(pos(1))],...
            ['Y: ', num2str(pos(2))]
        };
    end
end


%% ========== 子函数：保存图 => 带时间戳 (与原脚本相同) ==========
function saveFigureWithTimestamp(baseName)
    % 不再设置图像大小，使用MATLAB默认配置
    set(gcf,'PaperPositionMode','auto');
    timestampStr = datestr(now,'yyyymmdd_HHMMSS');
    outFile = sprintf('%s_%s.fig', baseName, timestampStr);
    savefig(outFile);
    
    fprintf('Figure saved: %s\n', outFile);
end