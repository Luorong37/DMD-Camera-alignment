function createBinaryImageUI()
    % 获取屏幕尺寸并设置为全屏
    screenSize = get(0, 'ScreenSize');
    
    % 创建UI窗口，使用全屏尺寸
    fig = uifigure('Position', [0 0 screenSize(3) screenSize(4)], 'Name', '图像二值化界面');

    % 原始图像轴
    ax1 = uiaxes(fig, 'Position', [50 100 screenSize(3)/2 - 100 screenSize(4) - 200]);
    title(ax1, '原始图像');
    
    % 二值化图像轴
    ax2 = uiaxes(fig, 'Position', [screenSize(3)/2 + 50 100 screenSize(3)/2 - 100 screenSize(4) - 200]);
    title(ax2, '二值化图像');
    
    % 读取图像并显示在左侧
    img = imread('peppers.png'); % 示例图片，可以换成你要使用的图片
    imshow(img, 'Parent', ax1);

    % 阈值输入框标签
    lbl1 = uilabel(fig, 'Position', [screenSize(3)/2 - 100 screenSize(4)/8 100 30], 'Text', '阈值 (%)');
    
    % 创建阈值输入框
    thresholdField = uieditfield(fig, 'numeric', 'Position',  [screenSize(3)/2 screenSize(4)/8 100 30], ...
        'ValueChangedFcn', @(src, event) updateBinaryImage(src.Value, minAreaField.Value, img, ax2, fig));
    
    % 最小面积输入框标签
    lbl2 = uilabel(fig, 'Position', [screenSize(3)/2 + 200 screenSize(4)/8 120 30], 'Text', '最小面积过滤');
    
    % 创建最小面积输入框
    minAreaField = uieditfield(fig, 'numeric', 'Position', [screenSize(3)/2 + 320 screenSize(4)/8 100 30], ...
        'ValueChangedFcn', @(src, event) updateBinaryImage(thresholdField.Value, src.Value, img, ax2, fig));
    
    % 初始化默认阈值和最小面积
    defaultThreshold = 50;
    defaultMinArea = 10;
    thresholdField.Value = defaultThreshold;
    minAreaField.Value = defaultMinArea;
    
    % 初始化二值化图像
    updateBinaryImage(defaultThreshold, defaultMinArea, img, ax2, fig);
    
    % 保存按钮
    saveButton = uibutton(fig, 'Text', '保存二值化结果', ...
        'Position', [screenSize(3)/2 + 150 screenSize(4)/8 - 50 150 30], ...
        'ButtonPushedFcn', @(src, event) saveBinaryImage(fig));
end

% 更新二值化图像函数，并检测边缘
function updateBinaryImage(thresholdPercent, minArea, img, ax, fig)
    % 将百分比转换为实际阈值
    threshold = 1 - thresholdPercent / 100;
    
    % 转换为灰度图像
    grayImg = rgb2gray(img);
    
    % 根据阈值进行二值化处理
    binaryImage = imbinarize(grayImg, threshold);
    
    % 过滤掉面积过小的区域
    filteredBinaryImage = bwareaopen(binaryImage, minArea);
    
    % 显示二值化图像
    imshow(filteredBinaryImage, 'Parent', ax);
    hold(ax, 'on'); % 允许在同一图像上绘图
    
    % 使用 bwboundaries 检测边缘
    boundaries = bwboundaries(filteredBinaryImage);
    
    % 在二值化图像上绘制边缘
    for k = 1:length(boundaries)
        boundary = boundaries{k};
        plot(ax, boundary(:,2), boundary(:,1), 'y', 'LineWidth', 2); % 用黄色线绘制边缘
    end
    hold(ax, 'off'); % 关闭 hold
    
    % 保存 binaryImage 和 boundaries 到应用程序数据中
    setappdata(fig, 'binaryImage', filteredBinaryImage);
    setappdata(fig, 'boundaries', boundaries);
end

% 保存二值化图像函数
function saveBinaryImage(fig)
    % 从应用程序数据中获取 binaryImage 和 boundaries
    binaryImage = getappdata(fig, 'binaryImage');
    boundaries = getappdata(fig, 'boundaries');
    
    % 将二值化图像和边缘保存到工作区
    assignin('base', 'binaryImageOutput', binaryImage);
    assignin('base', 'boundariesOutput', boundaries);
    disp('二值化图像已保存为变量 binaryImageOutput 和 boundariesOutput');
end
