function legendmarkeradjust(markerSize, orientation)
% LEGENDMARKERADJUST 调整图例中标记的大小
%
%   此函数用于调整当前图形中图例标记的大小
%
%   参数:
%     markerSize  - 标记大小（数值，默认为12）
%     orientation - 图例方向（'vertical'或'horizontal'，默认为'vertical'）
%
%   示例:
%     plot(rand(10,3));
%     h = legend('Data 1', 'Data 2', 'Data 3');
%     legendmarkeradjust(20); % 将图例标记大小设置为20
%
%   注意:
%     - 此函数适用于MATLAB 2019a及更高版本
%     - 对于某些图例类型可能不起作用

% 检查输入参数
if nargin < 1
    markerSize = 12;
end

if nargin < 2
    orientation = 'vertical';
end

% 获取当前图例句柄
h = findobj(gcf, 'Type', 'Legend');

if isempty(h)
    warning('未找到图例对象');
    return;
end

% 如果有多个图例，使用最后一个（最近创建的）
if length(h) > 1
    h = h(1);
end

% 获取图例中的所有对象
axchild = get(h, 'Children');

% 根据方向确定处理方式
isHorizontal = strcmpi(orientation, 'horizontal');

% 遍历所有图例子对象
for i = 1:length(axchild)
    try
        % 获取对象类型
        objType = get(axchild(i), 'Type');
        
        % 处理不同类型的对象
        if strcmp(objType, 'line')
            % 对于线型对象，设置标记大小
            if ~isempty(get(axchild(i), 'Marker')) && ~strcmp(get(axchild(i), 'Marker'), 'none')
                set(axchild(i), 'MarkerSize', markerSize);
                
                % 对于水平图例，可能需要调整线宽
                if isHorizontal
                    set(axchild(i), 'LineWidth', max(1, markerSize/10));
                end
            end
        elseif strcmp(objType, 'patch') || strcmp(objType, 'surface')
            % 对于面片对象，尝试调整其大小
            try
                % 获取当前XData和YData
                xdata = get(axchild(i), 'XData');
                ydata = get(axchild(i), 'YData');
                
                % 计算中心点
                xcenter = mean(xdata(:));
                ycenter = mean(ydata(:));
                
                % 计算当前大小
                width = max(xdata(:)) - min(xdata(:));
                height = max(ydata(:)) - min(ydata(:));
                
                % 计算缩放因子
                scaleFactor = markerSize / max(width, height) * 0.5;
                
                % 应用缩放
                newXData = (xdata - xcenter) * scaleFactor + xcenter;
                newYData = (ydata - ycenter) * scaleFactor + ycenter;
                
                % 设置新的数据
                set(axchild(i), 'XData', newXData);
                set(axchild(i), 'YData', newYData);
            catch
                % 忽略错误
            end
        end
    catch
        % 忽略无法处理的对象
    end
end

% 尝试使用ItemTokenSize属性（如果可用）
try
    if isHorizontal
        set(h, 'ItemTokenSize', [markerSize*1.5, markerSize]);
    else
        set(h, 'ItemTokenSize', [markerSize, markerSize]);
    end
catch
    % 忽略不支持的属性
end

% 刷新图形
drawnow;
end
