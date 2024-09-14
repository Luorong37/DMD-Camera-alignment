function fig = createBinaryImageUI(origin_image)
    
    % 获取屏幕尺寸并设置为全屏
    screenSize = get(0, 'ScreenSize');
    imageSize = size(origin_image);
    
    % 创建UI窗口，使用全屏尺寸
    fig = uifigure('Position', [0 0 screenSize(3) screenSize(4)], 'Name', 'Binary GUI');

    % 原始图像轴
    ax1 = uiaxes(fig, 'Position', [(screenSize(3)/2-imageSize(2))/2 (screenSize(4)-imageSize(1))/2 imageSize(2) imageSize(1)]);
    title(ax1, 'Origin Image','HorizontalAlignment', 'center');
    
    % 二值化图像轴
    ax2 = uiaxes(fig, 'Position', [(screenSize(3)*3/2-imageSize(2))/2 (screenSize(4)-imageSize(1))/2 imageSize(2) imageSize(1)]);
    title(ax2, 'Binary Image','HorizontalAlignment', 'center');
    
    % 显示在左侧
    imshow(imadjust(origin_image), 'Parent', ax1);
    
    % 输入框标签离底部距离
    bottom_edge = screenSize(4)/7;

    % 阈值输入框标签
    lbl1 = uilabel(fig, 'Position', [screenSize(3)/2 - 100 bottom_edge 100 30], 'Text', 'Threshold (%)');
    
    % 最小面积输入框标签
    lbl2 = uilabel(fig, 'Position', [screenSize(3)/2 + 200 bottom_edge 120 30], 'Text', 'Min Area Filter (pixel)');
    
    % 扩展距离输入框标签
    lbl3 = uilabel(fig, 'Position', [screenSize(3)/2 + 500 bottom_edge 160 30], 'Text', 'Expansion Distance (pixel)');
    
    % 创建阈值输入框
    thresholdField = uieditfield(fig, 'numeric', 'Position',  [screenSize(3)/2 bottom_edge 50 30]);
    
    % 创建最小面积输入框
    minAreaField = uieditfield(fig, 'numeric', 'Position', [screenSize(3)/2 + 340 bottom_edge 50 30]);
    
    % 创建扩展距离输入框
    expansionField = uieditfield(fig, 'numeric', 'Position', [screenSize(3)/2 + 660 bottom_edge 50 30]);
        
    % 初始化默认阈值、最小面积和扩展距离
    defaultThreshold = 99.5;
    defaultMinArea = 10;
    defaultExpansion = 0;
    
    thresholdField.Value = defaultThreshold;
    minAreaField.Value = defaultMinArea;
    expansionField.Value = defaultExpansion;
    
    % 为输入框设置回调函数，确保 minAreaField 已定义
    thresholdField.ValueChangedFcn = @(src, event) updateBinaryImage(src.Value, minAreaField.Value, expansionField.Value, origin_image, ax2, fig);
    minAreaField.ValueChangedFcn = @(src, event) updateBinaryImage(thresholdField.Value, src.Value, expansionField.Value, origin_image, ax2, fig);
    expansionField.ValueChangedFcn = @(src, event) updateBinaryImage(thresholdField.Value, minAreaField.Value, src.Value, origin_image, ax2, fig);

    % 初始化二值化图像
    updateBinaryImage(defaultThreshold, defaultMinArea, defaultExpansion, origin_image, ax2, fig);
    
    % 保存按钮
    saveButton = uibutton(fig, 'Text', 'Save binary result', ...
        'Position', [screenSize(3)/2 + 150 screenSize(4)/8 - 50 150 30], ...
        'ButtonPushedFcn', @(src, event) saveBinaryImage(fig));
end

% 更新二值化图像函数，并检测边缘
function updateBinaryImage(thresholdPercent, minArea, expansionDistance, img, ax, fig)
    % 将百分比转换为实际阈值
    threshold = 1 - thresholdPercent / 100;
    
    % 根据阈值进行二值化处理
    binaryImage = imbinarize(img, threshold);
    
    % 过滤掉面积过小的区域
    filteredBinaryImage = bwareaopen(binaryImage, minArea);
    
    % 显示二值化图像
    imshow(filteredBinaryImage, 'Parent', ax);
    hold(ax, 'on'); % 允许在同一图像上绘图
    
    % 使用 bwboundaries 检测边缘
    boundaries = bwboundaries(filteredBinaryImage);
    
    % 在二值化图像上绘制黄色边缘
    for k = 1:length(boundaries)
        boundary = boundaries{k};
        plot(ax, boundary(:,2), boundary(:,1), 'y', 'LineWidth', 2); % 黄色线绘制边缘
    end
    
    % 创建结构元素，用于膨胀边界
    se = strel('disk', expansionDistance);
    
    % 对二值化图像进行膨胀
    expandedBinaryImage = imdilate(filteredBinaryImage, se);
    
    % 使用 bwboundaries 检测扩展后的边缘
    expandedBoundaries = bwboundaries(expandedBinaryImage);
    
    % 在二值化图像上绘制红色扩展边缘
    for k = 1:length(expandedBoundaries)
        expandedBoundary = expandedBoundaries{k};
        plot(ax, expandedBoundary(:,2), expandedBoundary(:,1), 'r', 'LineWidth', 1.5); % 红色虚线绘制外扩边缘
    end
    
    hold(ax, 'off'); % 关闭 hold
    
    % 保存 binaryImage 和 boundaries 到应用程序数据中
    setappdata(fig, 'binaryImage', filteredBinaryImage);
    setappdata(fig, 'boundaries', boundaries);
    setappdata(fig, 'expandedBoundaries', expandedBoundaries);
    setappdata(fig, 'thresholdPercent', thresholdPercent);
    setappdata(fig, 'minArea', minArea);
    setappdata(fig, 'expansionDistance', expansionDistance);

end

% 保存二值化图像函数
% 保存二值化图像函数
function saveBinaryImage(fig)
    % 从应用程序数据中获取 binaryImage 和 boundaries
    binaryImage = getappdata(fig, 'binaryImage');
    boundaries = getappdata(fig, 'boundaries');
    expandedBoundaries = getappdata(fig, 'expandedBoundaries');
    thresholdPercent = getappdata(fig, 'thresholdPercent');
    minArea = getappdata(fig, 'minArea');
    expansionDistance = getappdata(fig, 'expansionDistance');
    
    % 创建一个结构体 rois 来存储结果
    rois.bwmask = binaryImage;                % 二值化图像
    rois.Position = boundaries;               % 原始边界位置
    rois.expandPosition = expandedBoundaries; % 扩展边界位置
    rois.thresholdPercent = thresholdPercent;
    rois.minArea = minArea;
    rois.expansionDistance = expansionDistance;
    
    % 将结构体保存到工作区
    assignin('base', 'rois', rois);

    disp('Binary image is saved as structure: rois.');
    msgbox('Binary results are saved in structure "rois". Close GUI window to continue.','Done','help');
end

