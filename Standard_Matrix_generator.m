function [numbers, coords, coordsflipped] = Standard_Matrix_generator(savepath)

% 定义矩阵尺寸和网格尺寸
matrixHeight = 1080;
matrixWidth = 1920;
gridHeight = 120; % 网格高度
gridWidth = 240; % 网格宽度
lineWidth = 10; % 网格线宽

% 创建一个1920×1080的全零矩阵
matrix = zeros(matrixHeight, matrixWidth);

% 绘制网格线段
for row = 1:gridHeight:matrixHeight
    % 绘制横线，考虑线宽
    for w = 0:lineWidth-1
        if row+w <= matrixHeight
            matrix(row+w, :) = 1;
        end
    end
end

for col = 1:gridWidth:matrixWidth
    % 绘制竖线，考虑线宽
    for w = 0:lineWidth-1
        if col+w <= matrixWidth
            matrix(:, col+w) = 1;
        end
    end
end

% 数字标记的列表和坐标
numbers = {};
coords = [];

% 在网格交叉点附近添加数字标记
figure;
imshow(matrix);
title('1920x1080 Matrix with 120x120 Grid and Numbered Crossings');
hold on;

fontSize = 40;
xOffset = 20; % 调整数字在x方向上的偏移量
yOffset = 60; % 调整数字在y方向上的偏移量

for row = 1:gridHeight:matrixHeight
    for col = 1:gridWidth:matrixWidth
        % 添加数字标记
        number = numel(numbers) + 1;
        numbers{end+1} = number;
        coords(end+1, :) = [row, col];
        
        % 在图像上标记数字
        text(col + xOffset, row + yOffset, num2str(number), ...
            'Color', 'white', 'FontSize', fontSize,'FontWeight','bold');
    end
end

numbers = cell2mat(numbers);
hold off;

% Save as .bmp
frame = getframe(gca);% 获取当前图形的框架
img = frame.cdata;% 将框架转换为图像数据
imgGray = rgb2gray(img); % 转换图像为灰度图像并保存为8位BMP
imgGray = imresize(imgGray, [matrixHeight, matrixWidth]);
imgInverted = 255 - imgGray;
imgInverted(imgInverted < 255) = 0;
imshow(imgInverted);
imwrite(imgInverted, fullfile(savepath,'0_Standard_Matrix.bmp'), 'bmp'); % 保存为bmp格式
imwrite(imgInverted, fullfile(savepath,'0_Standard_Matrix2.bmp'), 'bmp');

% Save flipped version
coordsflipped = coords;
coordsflipped(:,2) = matrixWidth - coordsflipped(:, 2) + 1;

imshow(fliplr(imgInverted));
imgFlipped = fliplr(imgInverted);
imwrite(imgFlipped, fullfile(savepath,'0_Flipped_Matrix.bmp'), 'bmp'); % 保存为bmp格式
imwrite(imgFlipped, fullfile(savepath,'0_Flipped_Matrix2.bmp'), 'bmp');

save(fullfile(savepath,'0_Standard parameters.mat'), 'numbers', 'coords', 'coordsflipped')

end