function plot_downstream_pol_profiles(all_radiationData, groupDirs, varargin)
    % =========================================================================
    % 功能：
    %   按"组"为单位绘制下游靶板附近的电子密度、电子温度和杂质浓度的极向分布子图，
    %   用于多算例对比。每个 group 在同一个 figure 中，子图叠加各算例(目录)的剖面曲线。
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
    %                  预定义名称为: 'favorable Bt', 'unfavorable Bt', 'w/o drift'
    %           false (默认): 使用目录名作为图例
    %
    % 输出：
    %   本函数无显式返回值，但会在屏幕上显示并保存一系列图形 (.fig) 文件：
    %     - 每个 group 对应 1 个 figure
    %     - figure 内含 6 个 subplot(3×2 布局)
    %     - 不同算例曲线叠加对比
    %
    % 说明：
    %   1) 绘制下游两个靶板附近的电子密度、电子温度和极向热流密度径向分布
    %   2) 极向热流密度 q_poloidal = (fhi_mdf(:,:,1) + fhe_mdf(:,:,1)) ./ (gmtry.gs(:,:,1) .* gmtry.qz(:,:,2))
    %   3) 外靶板（target1_j_index）热流方向取反
    %   4) 横坐标使用物理坐标(相对于分离面 x=0)
    %   5) 若要对组或目录进行颜色/marker 区分，可在下方预先定义。
    %
    % 作者：XXX
    % 日期：2025-01-23
    % 修改：2025-01-24  添加可选的预定义图例名称
    %       2025-01-25  简化图例类型参数为 usePredefinedLegend (boolean)
    %       2025-01-26  修改为绘制极向热流密度，并考虑外靶板热流方向

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

    % ========== 网格与索引的示例值 ==========
    radial_index_14_gmtry  = 14;   % 用于界定分离面
    radial_index_15_gmtry  = 15;   % 用于界定分离面
    target1_j_index = 2;         % 下游靶板1 附近的 poloidal 索引 (靠近 j=1)
    target2_j_index = 96;        % 下游靶板2 附近的 poloidal 索引 (靠近 j=nyd)

    % ========== 遍历各组，每组输出 1 个 figure ==========
    num_groups = length(groupDirs);

    for g = 1 : num_groups

        % 取出第 g 组的目录列表
        currentGroup = groupDirs{g};

        % === 新建一个 figure (针对第 g 组) ===
        figTitle = sprintf('Group %d: Target Profiles Comparison', g);
        figure('Name', figTitle, 'NumberTitle', 'off', 'Color','w');
        % 不再指定figure大小，使用MATLAB默认配置

        % 先获取 subplot 句柄
        ax1  = subplot(3,2,1); hold(ax1,'on'); % Target 1, ne
        ax2  = subplot(3,2,2); hold(ax2,'on'); % Target 2, ne
        ax3  = subplot(3,2,3); hold(ax3,'on'); % Target 1, te
        ax4  = subplot(3,2,4); hold(ax4,'on'); % Target 2, te
        ax5  = subplot(3,2,5); hold(ax5,'on'); % Target 1, q_poloidal
        ax6  = subplot(3,2,6); hold(ax6,'on'); % Target 2, q_poloidal
        
        % 强制设置子图的大小和位置
        % Position格式: [left bottom width height]，值范围0-1（归一化坐标）
        set(ax1, 'Position', [0.10 0.71 0.38 0.22]); % 左上
        set(ax2, 'Position', [0.55 0.71 0.38 0.22]); % 右上
        set(ax3, 'Position', [0.10 0.41 0.38 0.22]); % 左中
        set(ax4, 'Position', [0.55 0.41 0.38 0.22]); % 右中 
        set(ax5, 'Position', [0.10 0.11 0.38 0.22]); % 左下
        set(ax6, 'Position', [0.55 0.11 0.38 0.22]); % 右下
        
        % 设置所有子图的坐标轴属性
        axList = [ax1, ax2, ax3, ax4, ax5, ax6];
        for ax = axList
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

        % 预定义的图例名称
        predefined_legend_names = {'$\mathrm{fav.}~B_{\mathrm{t}}$', '$\mathrm{unfav.}~B_{\mathrm{t}}$', '$\mathrm{w/o~drift}$'};

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

            % -- 1) 下游方向 Target 1 (j=target1_j_index) --
            Y_down1_target = gmtry.hy(target1_j_index,2:end-1);
            W_down1_target = [0.5*Y_down1_target(1), 0.5*(Y_down1_target(2:end)+Y_down1_target(1:end-1))];
            hy_downstream_center_1_target = cumsum(W_down1_target);
            separatrix_downstream_1_target = (hy_downstream_center_1_target(radial_index_14_gmtry) + ...
                                       hy_downstream_center_1_target(radial_index_15_gmtry)) / 2;
            x_downstream_target1 = hy_downstream_center_1_target - separatrix_downstream_1_target;

            % -- 2) 下游方向 Target 2 (j=target2_j_index) --
            Y_down2_target = gmtry.hy(target2_j_index,2:end-1);
            W_down2_target = [0.5*Y_down2_target(1), 0.5*(Y_down2_target(2:end)+Y_down2_target(1:end-1))];
            hy_downstream_center_2_target = cumsum(W_down2_target);
            separatrix_downstream_2_target = (hy_downstream_center_2_target(radial_index_14_gmtry) + ...
                                       hy_downstream_center_2_target(radial_index_15_gmtry)) / 2;
            x_downstream_target2 = hy_downstream_center_2_target - separatrix_downstream_2_target;


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

            % 计算极向热流密度 q_poloidal = (fhi_mdf(:,:,1) + fhe_mdf(:,:,1)) ./ (gmtry.gs(:,:,1) .* gmtry.qz(:,:,2))
            q_poloidal_2D = (fhi_mdf(:,:,1) + fhe_mdf(:,:,1)) ./ (gmtry.gs(:,:,1) .* gmtry.qz(:,:,2));
            
            % 计算杂质浓度（杂质总密度除以电子密度）
            if isfield(plasma, 'na')
                % 计算杂质总密度（从Ne1+到Ne10+的总和，即第3维从4到13）
                impurity_density_total = sum(plasma.na(2:end-1,2:end-1,4:13), 3);
                % 加上中性Ne原子
                impurity_density_total = impurity_density_total + neut.dab2(:,:,2);
                % % 杂质浓度 = 杂质总密度 / 电子密度
                % impurity_concentration_2D = impurity_density_total ./ ne_2D(2:end-1,2:end-1);
            else
                fprintf('Warning: plasma.na field not found for impurity calculation in %s\n', dirName);
                impurity_density_total = zeros(size(ne_2D)); % 如果没有na字段，则用零矩阵代替
            end


            % ====== 分配颜色 / marker (与 k 对应) ======
            dir_color  = line_colors(mod(k-1,size(line_colors,1))+1,:);
            % 去掉marker，只使用颜色区分
            % 增加线宽以便更好区分
            plotStyle  = {'-','Color', dir_color, 'LineWidth',linewidth};

            % ----------------------------------------------------------------
            % (1) Inner Target electron density (target2_j_index,:)
            % ----------------------------------------------------------------
            h1 = plot(ax1, x_downstream_target2, ne_2D(target2_j_index,:), plotStyle{:});
            set(h1, 'DisplayName', simplifiedDirName);
            set(h1, 'UserData', dirName);  % 用于 datacursor
            % 在分离面 x=0 画一条线
            plot(ax1, [0 0], ylim(ax1),'k--','LineWidth',1.2);
            xlabel(ax1,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
            ylabel(ax1,'$n_{\mathrm{e}}$ (m$^{-3}$)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
            ax1_handles(end+1) = h1; ax1_legend_entries{end+1} = simplifiedDirName;

            % ----------------------------------------------------------------
            % (2) Outer Target electron density (target1_j_index,:)
            % ----------------------------------------------------------------
            h2 = plot(ax2, x_downstream_target1, ne_2D(target1_j_index,:), plotStyle{:});
            set(h2,'UserData', dirName);
            plot(ax2, [0 0], ylim(ax2),'k--','LineWidth',1.2);
            xlabel(ax2,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
            ylabel(ax2,'$n_{\mathrm{e}}$ (m$^{-3}$)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
            ax2_handles(end+1) = h2; ax2_legend_entries{end+1} = simplifiedDirName;

            % ----------------------------------------------------------------
            % (3) Inner Target electron temperature (target2_j_index,:)
            % ----------------------------------------------------------------
            h3 = plot(ax3, x_downstream_target2, te_2D(target2_j_index,:), plotStyle{:});
            set(h3,'UserData', dirName);
            plot(ax3, [0 0], ylim(ax3),'k--','LineWidth',1.2);
            xlabel(ax3,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
            ylabel(ax3,'$T_{\mathrm{e}}$ (eV)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
            ax3_handles(end+1) = h3; ax3_legend_entries{end+1} = simplifiedDirName;

            % ----------------------------------------------------------------
            % (4) Outer Target electron temperature (target1_j_index,:)
            % ----------------------------------------------------------------
            h4 = plot(ax4, x_downstream_target1, te_2D(target1_j_index,:), plotStyle{:});
            set(h4,'UserData', dirName);
            plot(ax4, [0 0], ylim(ax4),'k--','LineWidth',1.2);
            xlabel(ax4,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
            ylabel(ax4,'$T_{\mathrm{e}}$ (eV)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
            ax4_handles(end+1) = h4; ax4_legend_entries{end+1} = simplifiedDirName;

            % ----------------------------------------------------------------
            % (5) Inner Target Impurity concentration (target2_j_index,:)
            % ----------------------------------------------------------------
            h5 = plot(ax5, x_downstream_target2, impurity_density_total(target2_j_index,:), plotStyle{:});
            set(h5,'UserData', dirName);
            plot(ax5, [0 0], ylim(ax5),'k--','LineWidth',1.2);
            xlabel(ax5,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
            ylabel(ax5,'$n_{\mathrm{imp}}$ (m$^{-3}$)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
            ylim(ax5, [0 10e18]); % 设置y轴范围为0到8×10^18
            ax5_handles(end+1) = h5; ax5_legend_entries{end+1} = simplifiedDirName;

            % ----------------------------------------------------------------
            % (6) Outer Target Impurity concentration (target1_j_index,:)
            % ----------------------------------------------------------------
            h6 = plot(ax6, x_downstream_target1, impurity_density_total(target1_j_index,:), plotStyle{:});
            set(h6,'UserData', dirName);
            plot(ax6, [0 0], ylim(ax6),'k--','LineWidth',1.2);
            xlabel(ax6,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
            ylabel(ax6,'$n_{\mathrm{imp}}$ (m$^{-3}$)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
            ylim(ax6, [0 10e18]); % 设置y轴范围为0到8×10^18
            ax6_handles(end+1) = h6; ax6_legend_entries{end+1} = simplifiedDirName;


        end % (end of each directory in group g)

        % 同步左右两侧的y轴范围
        linkaxes([ax1, ax2], 'y');
        linkaxes([ax3, ax4], 'y');
        linkaxes([ax5, ax6], 'y');
        
        % ========== 在每个 subplot 上加 legend ==========
        legend(ax1, ax1_handles, ax1_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);
        legend(ax2, ax2_handles, ax2_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);
        legend(ax3, ax3_handles, ax3_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);
        legend(ax4, ax4_handles, ax4_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);
        legend(ax5, ax5_handles, ax5_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);
        legend(ax6, ax6_handles, ax6_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);

        % 增强所有坐标轴刻度字体
        set(ax1, 'FontName', fontName, 'FontSize', xlabelsize);
        set(ax2, 'FontName', fontName, 'FontSize', xlabelsize);
        set(ax3, 'FontName', fontName, 'FontSize', xlabelsize);
        set(ax4, 'FontName', fontName, 'FontSize', xlabelsize);
        set(ax5, 'FontName', fontName, 'FontSize', xlabelsize);
        set(ax6, 'FontName', fontName, 'FontSize', xlabelsize);
        
        % 不再手动调整子图间距，由MATLAB自行决定布局
        % set(gcf, 'DefaultAxesLooseInset', [0,0,0,0]);
        % pos = get(gcf, 'Position');
        % set(gcf, 'Position', [pos(1), pos(2), pos(3), pos(4)]);
        
        % ========== Data Cursor mode ==========
        dcm = datacursormode(gcf);
        set(dcm,'UpdateFcn',@myDataCursorUpdateFcn);
        
        % 不再应用tightfig
        % tightfig;

        % ========== 保存图（带时间戳，避免覆盖） ==========
        saveFigureWithTimestamp(sprintf('target_profiles_group%d', g));

        fprintf('>>> Finished group %d (Target Profiles) with %d directories.\n', g, length(currentGroup));

    end % (end for each group)

    fprintf('\nAll groups of target profiles have been plotted in separate figures.\n');

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