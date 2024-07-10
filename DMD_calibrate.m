%% Pre Setting

dmd_width = 1920;
dmd_height = 1080;
dmd_size = [dmd_height, dmd_width]; % DMD分辨率
camera_width = 2304;
camera_height = 2304;
camera_size = [camera_height, camera_width]; % Camera分辨率

% Pre generation of standard grid photo
savepath = 'E:\1_Data\Lichen\20240708_DMDtest';
calipath = fullfile(savepath,'DMD calibration');
mkdir(calipath);
Standard_Matrix_generator(calipath);
load(fullfile(calipath,'0_Standard parameters.mat'));

%% Take a photo

% Now, images are generated onto savepath. Start the DMD and input images.
% chose the taken photo under DMD with calibrate matrix by camera
selected_image = 'E:\1_Data\Lichen\20240708_DMDtest\FLX4-405-cubeset1-1.tif';

% judge if flipped
flipped = true;
if flipped
    standard_photo = fullfile(calipath,'0_Flipped_Matrix.bmp');
    coords = coordsflipped;

else
    standard_photo = fullfile(calipath,'0_Standard_Matrix.bmp');
    coords = coords;
end

% Select 3 points on selected_photo
% 打开并显示图像
im = imread(selected_image);
imshow(imadjust(im));
title('Select three points and enter corresponding numbers');

% 初始化变量
points = zeros(3, 2); % 存储三个点的坐标
selected_numbers = zeros(3, 1); % 存储三个点的数字

% 选择三个点并输入对应的数字
for i = 1:3
    [x, y] = ginput(1); % 选择一个点
    points(i, :) = [x, y]; % 记录点的坐标
    
    % 输入对应的数字
    prompt = sprintf('Enter the number for point %d:', i);
    number = inputdlg(prompt, 'Input Number', 1, {'0'});
    
    % 将输入的数字转换为数值并存储
    selected_numbers(i) = str2double(number{1});
    
    % 在图像上标记点和数字
    hold on;
    plot(x, y, 'r+', 'MarkerSize', 10, 'LineWidth', 2);
    text(x + 10, y, number{1}, 'Color', 'red', 'FontSize', 12);
    hold off;
end

fig_filename = fullfile(calipath, '1_selected_Points.fig');
png_filename = fullfile(calipath, '1_selected_Points.png');

saveas(gcf, fig_filename, 'fig');
saveas(gcf, png_filename, 'png');

% Calculate Transform Matrix
points_standard = coords(selected_numbers,:);


T_points = [points(1,1), points(2,1),points(3,1);
            points(1,2), points(2,2),points(3,2);
            1,1,1];

T_points_standard = [points_standard(1,1), points_standard(2,1),points_standard(3,1);
                     points_standard(1,2), points_standard(2,2),points_standard(3,2);
                     1,1,1];

T = T_points_standard / T_points;

save(fullfile(calipath,'1_Matrix parameters.mat'), 'T_points', 'T_points_standard', 'T','selected_numbers')


%% Generate mask

% select a ROI in view
view_image = 'E:\1_Data\Lichen\20240708_DMDtest\mix-5616.tif';
view = imread(view_image);
rois = drawROI(view);

% create save file
[imagepath,imagename] = fileparts(view_image);
createpath = fullfile(imagepath,imagename);
mkdir(createpath);
fig_filename = fullfile(createpath, '1_selectedROI.fig');
png_filename = fullfile(createpath, '1_selectedROI.png');
saveas(gcf, fig_filename, 'fig');
saveas(gcf, png_filename, 'png');


% generate a mask
bwmask_DMD = zeros(dmd_height,dmd_width);
bwmask_camera = rois.bwmask;

save_path_rois = fullfile(createpath,'eachROI');
mkdir(save_path_rois);

for i = 1: size(rois.Position,2)
    npoints = size(rois.Position{i}, 1); % 将points转换为齐次坐标
    positions = rois.Position{i};
    
    points_homogeneous = [positions, ones(npoints, 1)]; % Nx3 矩阵
    transformed_points_homogeneous = (T * points_homogeneous')';% 进行仿射变换
    transformed_points = transformed_points_homogeneous(:, 1:2);% 转换回笛卡尔坐标
    
    % transform to mask
    mask = poly2mask( transformed_points(:, 2),transformed_points(:, 1),dmd_height,dmd_width);
    bwmask_DMD(mask) = i;

    mask = uint8(mask*255);
    imwrite(mask, fullfile(save_path_rois,sprintf('ROI %d.bmp', i)));
  
end

bwmask_DMD(bwmask_DMD ~= 0) = 255;
bwmask_DMD = uint8(bwmask_DMD);

bwmask_camera(bwmask_camera ~= 0) = 255;
bwmask_camera = uint8(bwmask_camera);

imwrite(bwmask_DMD, fullfile(createpath,'2_bwmask_DMD.bmp'));
imwrite(bwmask_DMD, fullfile(createpath,'2_bwmask_DMD2.bmp'));

imwrite(bwmask_camera, fullfile(createpath,'3_bwmask_camera.tif'));
imwrite(bwmask_camera, fullfile(createpath,'3_bwmask_camera.png'));
%%





