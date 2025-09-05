function plot_example_new_feature(all_radiationData, groupDirs, domain, plot_type)
% PLOT_EXAMPLE_NEW_FEATURE 示例新功能绘图脚本
%   这是一个示例脚本，展示如何创建新的绘图功能并集成到动态绘图系统中
%
%   参数:
%     all_radiationData - 包含所有SOLPS仿真辐射数据的结构体数组
%     groupDirs - 包含分组目录信息的元胞数组
%     domain - 绘图域选择 (0-全域, 1-EAST上偏滤器, 2-EAST下偏滤器)
%     plot_type - 绘图类型 ('contour', 'surface', '3d')
%
%   示例:
%     plot_example_new_feature(all_radiationData, groupDirs, 0, 'contour')

% 参数验证
if nargin < 3
    domain = 0; % 默认全域
end
if nargin < 4
    plot_type = 'contour'; % 默认等高线图
end

fprintf('\n=== 示例新功能绘图脚本 ===\n');
fprintf('绘图域: %d\n', domain);
fprintf('绘图类型: %s\n', plot_type);
fprintf('数据组数: %d\n', length(all_radiationData));

% 检查数据有效性
if isempty(all_radiationData)
    error('输入数据为空');
end

% 创建图形窗口
figure('Name', 'Example New Feature Plot', 'NumberTitle', 'off');

% 根据数据组数决定子图布局
num_groups = length(all_radiationData);
if num_groups <= 3
    subplot_rows = 1;
    subplot_cols = num_groups;
elseif num_groups <= 6
    subplot_rows = 2;
    subplot_cols = 3;
else
    subplot_rows = 3;
    subplot_cols = 3;
end

% 为每个数据组创建子图
for group_idx = 1:min(num_groups, 9) % 最多显示9个子图
    subplot(subplot_rows, subplot_cols, group_idx);
    
    % 获取当前组的数据
    current_data = all_radiationData(group_idx);
    
    % 检查必要的数据字段
    if ~isfield(current_data, 'crx') || ~isfield(current_data, 'cry')
        fprintf('警告: 第%d组数据缺少坐标信息\n', group_idx);
        continue;
    end
    
    % 获取坐标数据
    x_coords = current_data.crx;
    y_coords = current_data.cry;
    
    % 创建示例数据（这里使用电子密度作为示例）
    if isfield(current_data, 'ne')
        plot_data = current_data.ne;
        data_label = 'Electron Density (m^{-3})';
    else
        % 如果没有电子密度数据，创建示例数据
        plot_data = rand(size(x_coords)) * 1e19;
        data_label = 'Example Data';
        fprintf('警告: 第%d组数据缺少电子密度信息，使用示例数据\n', group_idx);
    end
    
    % 根据域选择调整数据范围
    switch domain
        case 1 % EAST上偏滤器
            y_mask = y_coords > 0;
            x_coords = x_coords(y_mask);
            y_coords = y_coords(y_mask);
            plot_data = plot_data(y_mask);
        case 2 % EAST下偏滤器
            y_mask = y_coords < 0;
            x_coords = x_coords(y_mask);
            y_coords = y_coords(y_mask);
            plot_data = plot_data(y_mask);
        % case 0: 全域，不需要调整
    end
    
    % 根据绘图类型创建图形
    try
        switch lower(plot_type)
            case 'contour'
                % 等高线图
                if length(unique(x_coords)) > 1 && length(unique(y_coords)) > 1
                    % 创建网格
                    [X, Y] = meshgrid(linspace(min(x_coords), max(x_coords), 50), ...
                                      linspace(min(y_coords), max(y_coords), 50));
                    % 插值数据
                    Z = griddata(x_coords, y_coords, plot_data, X, Y, 'linear');
                    contourf(X, Y, Z, 20);
                    colorbar;
                else
                    scatter(x_coords, y_coords, 50, plot_data, 'filled');
                    colorbar;
                end
                
            case 'surface'
                % 表面图
                if length(unique(x_coords)) > 1 && length(unique(y_coords)) > 1
                    [X, Y] = meshgrid(linspace(min(x_coords), max(x_coords), 30), ...
                                      linspace(min(y_coords), max(y_coords), 30));
                    Z = griddata(x_coords, y_coords, plot_data, X, Y, 'linear');
                    surf(X, Y, Z);
                    shading interp;
                    colorbar;
                    view(3);
                else
                    scatter3(x_coords, y_coords, plot_data, 50, plot_data, 'filled');
                    colorbar;
                end
                
            case '3d'
                % 3D散点图
                scatter3(x_coords, y_coords, plot_data, 50, plot_data, 'filled');
                colorbar;
                view(3);
                
            otherwise
                % 默认散点图
                scatter(x_coords, y_coords, 50, plot_data, 'filled');
                colorbar;
        end
        
        % 设置图形属性
        xlabel('R (m)');
        ylabel('Z (m)');
        if strcmpi(plot_type, 'surface') || strcmpi(plot_type, '3d')
            zlabel(data_label);
        end
        
        % 设置标题
        if exist('groupDirs', 'var') && ~isempty(groupDirs) && group_idx <= length(groupDirs)
            title(sprintf('Group %d: %s', group_idx, groupDirs{group_idx}));
        else
            title(sprintf('Group %d', group_idx));
        end
        
        % 设置颜色条标签
        c = colorbar;
        c.Label.String = data_label;
        
        % 设置坐标轴等比例
        axis equal;
        grid on;
        
    catch ME
        fprintf('绘图错误 (第%d组): %s\n', group_idx, ME.message);
        text(0.5, 0.5, sprintf('绘图错误\n%s', ME.message), ...
             'Units', 'normalized', 'HorizontalAlignment', 'center');
    end
end

% 设置整体图形标题
domain_names = {'全域', 'EAST上偏滤器', 'EAST下偏滤器'};
domain_name = domain_names{domain + 1};
sgtitle(sprintf('示例新功能绘图 - %s - %s', domain_name, upper(plot_type)));

% 调整子图间距
if num_groups > 1
    set(gcf, 'Position', [100, 100, 1200, 800]);
end

% 保存图形
try
    save_filename = sprintf('example_new_feature_%s_domain%d.fig', plot_type, domain);
    savefig(gcf, save_filename);
    fprintf('图形已保存: %s\n', save_filename);
catch ME
    fprintf('保存图形失败: %s\n', ME.message);
end

fprintf('=== 示例新功能绘图完成 ===\n');

end
