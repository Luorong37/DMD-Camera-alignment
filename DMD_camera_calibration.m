%% DMD_calibrate
% powerd by Luorong Liu-Yang at 20240710
% update at 20240907

% This function performs the following tasks:
% 1. Sets up and generates a standard grid photo and saves the calibration parameters.
% 2. Takes a photo with projected grid, selects 3 points on the image, and calculates a transformation matrix.
% 3. Generates a mask based on a selected region of interest (ROI) and applies the transformation matrix.

% You can run each section in order if required file prepared.
%% Pre Setting
clear;clc;

% Pre setting of DMD  and Camera
dmd_width = 1920;
dmd_height = 1080;
dmd_size = [dmd_height, dmd_width];

% Pre generation of standard grid photo
savepath = uigetdir('Select a folder as save path');% input save folder path
if savepath == 0
    error('No folder selected.');
else
    disp(['Savepath: ', savepath]);
end

% choose a cube set.
cube_set = {'cube1：488&561','cube2：488&594','cube3：488&640','cube4：532&640'};
cube_choice = listdlg('ListString',cube_set,'PromptString','Choose one cube set','SelectionMode','single');
disp([cube_set{cube_choice}, ' is selected.'])

% choose a calibrate camera
camera_choice = questdlg('Choose a calibrate camera:','Select Option','2326','2325','Cancel','Cancel');
disp(['Camera ', camera_choice, ' is selected.'])

% choose whether calibrate
calibrate_choice = questdlg('Calibrate this time？','Select Option','Yes','No','Cancel','Cancel');
switch calibrate_choice
% this means you should calibrate the camera and DMD this time
case 'Yes'
    calibrate = true;

    % generate calibration folder
    calipath = fullfile(savepath,'DMD calibration');
    mkdir(calipath);

    % generate calibration files
    Standard_Matrix_generator(calipath);
    load(fullfile(calipath,'0_Standard parameters.mat'));
    close();
    fprintf('Standard grids generated\n')

    % display a calibrate hint
    switch camera_choice
    case '2326'
        flipped = true; % 2326 for true and 2325 for false
        h = msgbox(['Camera 2326 is selected. Please choose 0_Flipped_Matrix.bmp for DMD calibration. ' ...
            'Click OK when a .tif photo of the projected calibration matrix taken by the camera is ready.'],'Wait','help');
        uiwait(h);
    case '2325'
        flipped = false; % 2326 for true and 2325 for false
        h = msgbox(['Camera 2325 is selected. Please choose 0_Standard_Matrix.bmp for DMD calibration. ' ...
            'Click OK when a .tif photo of the projected calibration matrix taken by the camera is ready.'],'Wait','help');
        uiwait(h);
    otherwise
        disp('Canceled')
        return;
    end

% this means you should NOT calibrate the camera and DMD this time.
% Previous calbrate results will be used
case 'No'
    calibrate = false;

    % load previous parameters
    parapath = 'C:\Users\DELL\Desktop\DMD\1 Code\DMD-Camera-alignment\Standard_T_matrix\2024.09.13';
    parafile = fullfile(parapath,camera_choice,cube_set{cube_choice},'1_Matrix parameters.mat');
    try
        load(parafile);
        h = msgbox('Calibrate canceled, previous T will be used. Click OK when a .tif file is ready to generate the mask.','Wait','help');
        uiwait(h);
    catch
        errordlg('No previous T saved!');
        error('No previous T saved!');
    end
otherwise
    disp('Canceled')
    return;
end

%% Take a photo

% Now, images are generated in savepath. Start the DMD and input grid images into DMD.
% Take a photo of projected calibrate matrix.

% If NOT calibrate, ignore this part

if calibrate
% choose a tif photo
[selected_name,selected_path] = uigetfile('*.tif','Choose a tif photo of projected calibrate matrix taken by camera',savepath);
selected_image = fullfile(selected_path,selected_name);
if selected_name == 0
    error('No file selected.');
else
    disp(['Selected image: ', selected_image]);
end

% judge which maritx are used
if flipped
    standard_photo = fullfile(calipath,'0_Flipped_Matrix.bmp');
    coords = coordsflipped;
else
    standard_photo = fullfile(calipath,'0_Standard_Matrix.bmp');
    coords = coords;
end

% Select 3 points in a triangle on selected photo
% Open and display the image
fig = figure();
im = imread(selected_image);
imshow(imadjust(im));
set(fig,'Position',get(0,'Screensize'))
title('Select three points and enter corresponding numbers');

% Initialize variables
points = zeros(3, 2); % Store coordinates of three points
selected_numbers = zeros(3, 1); % Store numbers of three points

% Select three points and input corresponding numbers
for i = 1:3
    % Select a point
    [x, y] = ginput(1);
    points(i, :) = [x, y]; % Record coordinates of the point

    % Input corresponding number
    prompt = sprintf('Enter the number for point %d:', i);
    number = inputdlg(prompt, 'Input Number', 1, {'0'});
    selected_numbers(i) = str2double(number{1}); % Convert input number to numeric and store

    % Mark the point and number on the image
    hold on;
    plot(x, y, 'r+', 'MarkerSize', 10, 'LineWidth', 2);
    text(x + 10, y, number{1}, 'Color', 'red', 'FontSize', 12);
    hold off;
end

fig_filename = fullfile(calipath, '1_selected_Points.fig');
png_filename = fullfile(calipath, '1_selected_Points.png');

saveas(gcf, fig_filename, 'fig');
saveas(gcf, png_filename, 'png');

close(fig)

% Calculate Transform Matrix
points_standard = coords(selected_numbers,:);

T_points = [points(1,1), points(2,1),points(3,1);
    points(1,2), points(2,2),points(3,2);
    1,1,1];

T_points_standard = [points_standard(1,1), points_standard(2,1),points_standard(3,1);
    points_standard(1,2), points_standard(2,2),points_standard(3,2);
    1,1,1];

T = T_points_standard / T_points;

% save matrix parameter
save(fullfile(calipath,'1_Matrix parameters.mat'), 'T_points', 'T_points_standard', 'T','selected_numbers','im')

% save matrix parameter to statistic folder
statfolder = 'C:\Users\DELL\Desktop\DMD\1 Code\DMD-Camera-alignment\T_stat';
time = strrep(string(datetime('now')), ':', '-');
statpath = fullfile(statfolder,camera_choice,cube_set{cube_choice},time);
mkdir(statpath);
save(fullfile(statpath,'1_Matrix parameters.mat'), 'T_points', 'T_points_standard', 'T','selected_numbers','im')

fprintf('Calibration compeleted\n')
display(T)

h = msgbox('Calibrate compeleted. Click OK when a .tif file is ready to generate the mask.','Wait','help');
uiwait(h);
end
%% Generate mask

% In this section, you have two mode to generate a mask: 'Manually in
% Matlab' or 'From Fiji'.
% 'Manually in Matlab': you will select polygons for ROIs in a matlab
% figure.
% 'From Fiji': you should give a folder with .roi files, which created by
% Fiji. 
% 
% in one case, if you want to create a mask by setting threshold, follow these steps:
        % open image in imageJ, first set a threshold: (Image>Adjust>Threshold)
        % or (Ctrl+Shift+T), then transform to ROIs: (Analyze>Analyze Particles),
        % select Add to manager, next open ROI manager: (Analyze>Tools>ROI Manager),
        % save all ROIs：(More>Save), Unzip saved zip to roi_folder.
%        
% in other case, this program will generate a reverse mask, so you need not
% to select the reversed ROI if you need.

% preset
bwmask_DMD = zeros(dmd_height,dmd_width);
blank = zeros(dmd_height,dmd_width);
view_size = size(im);

% select a view image
[view_name,view_path] = uigetfile('*.tif','Select a tif image',savepath);
view_image = fullfile(view_path,view_name);
if view_name == 0
    error('No file selected.');
else
    disp(['Selected image: ', view_image]);
end
view = imread(view_image);

% create save folder
[imagepath,imagename] = fileparts(view_image);
createpath = fullfile(imagepath,imagename);
mkdir(createpath);

% Choose a ROI select mode
choice = questdlg('Choose a ROI select mode:','Select Option','Manually in Matlab','Create binary mask in Matlab','From Fiji','Manually in Matlab');
switch choice
    case 'Manually in Matlab'
        % manually select ROIs
        rois = drawROI(view);
        fig_filename = fullfile(createpath, '1_selectedROI.fig');
        png_filename = fullfile(createpath, '1_selectedROI.png');
        saveas(gcf, fig_filename, 'fig');
        saveas(gcf, png_filename, 'png');
        close()
    case 'Create binary mask in Matlab'
        fig = createBinaryImageUI(view);
        waitfor(fig);
        fig_filename = fullfile(createpath, '1_selectedROI.fig');
        savefig(fig, fig_filename);
        png_filename = fullfile(createpath, '1_selectedROI.png');
        ax = findall(fig, 'Type', 'axes');
        % 将特定的轴或整个图形保存为png
        exportgraphics(ax(2), png_filename, 'Resolution', 300); % 选择第一个图形轴保存        
    case 'From Fiji'
        % load fiji rois
        roi_folder = uigetdir(savepath,'Select a unzipped ROI floder');
        disp(['Selected ROIset: ',roi_folder])
        rois = import_fiji_rois_to_bwmask(roi_folder, createpath, view_size);
    otherwise
        disp('Canceled')
        return;
end

% get bwmask
bwmask_camera = rois.bwmask;

% generate and save masks
save_path_rois = fullfile(createpath,'eachROI');
save_path_rois_8bit = fullfile(createpath,'eachROI','8bit');
save_path_rois_1bit = fullfile(createpath,'eachROI','1bit');
mkdir(save_path_rois);
mkdir(save_path_rois_8bit);
mkdir(save_path_rois_1bit);

% if expand was selected, then generate expand ROIs
if rois.expansionDistance ~= 0
    boundaries = rois.expandPosition;
else
    boundaries = rois.Position;
end

% generate mask by each ROI
for i = 1: size(boundaries,2)
    % Convert points to homogeneous coordinates
    npoints = size(boundaries{i}, 1);  % number of points in a ROI
    positions = boundaries{i}; % positions of points in a ROI

    points_homogeneous = [positions, ones(npoints, 1)]; % Nx3 matrix
    transformed_points_homogeneous = (T * points_homogeneous')';  % Perform affine transformation
    transformed_points = transformed_points_homogeneous(:, 1:2);  % Convert back to Cartesian coordinates

    % transform to mask
    mask = poly2mask(transformed_points(:, 2),transformed_points(:, 1),dmd_height,dmd_width);
    bwmask_DMD(mask) = i;

    % save as 8bit file
    mask = uint8(mask*255);
    imwrite(mask, fullfile(save_path_rois_8bit,sprintf('ROI %d.bmp', i)));

    % save as 1bit file
    imwrite(logical(mask), fullfile(save_path_rois,'1bit',sprintf('ROI %d.bmp', i)));
    % imwrite(blank, fullfile(save_path_rois_1bit,sprintf('ROI %d.1.bmp', i)));
end

% make all ROI be same intensity
bwmask_DMD(bwmask_DMD ~= 0) = 255;
bwmask_DMD = uint8(bwmask_DMD);

% save a reverse mask
bwmask_DMD_reverse = zeros(dmd_size);
view_position = [0,0;0,view_size(2);view_size;view_size(1),0];
view_points_homogeneous = [view_position, ones(4, 1)]; % Nx3 matrix
view_transformed_points_homogeneous = (T * view_points_homogeneous')';  % Perform affine transformation
view_transformed_points = view_transformed_points_homogeneous(:, 1:2);  % Convert back to Cartesian coordinates
view_mask = poly2mask(view_transformed_points(:, 2),view_transformed_points(:, 1),dmd_height,dmd_width);

% reset all pixels not in view
bwmask_DMD_reverse(bwmask_DMD ~= 0) = 0;
bwmask_DMD_reverse(bwmask_DMD == 0) = 255;
bwmask_DMD_reverse(view_mask == 0) = 0;
bwmask_DMD_reverse = uint8(bwmask_DMD_reverse);

% create a camera mask
bwmask_camera(bwmask_camera ~= 0) = 255;
bwmask_camera = uint8(bwmask_camera);
% save a reverse mask
bwmask_camera_reverse = zeros(size(bwmask_camera));
bwmask_camera_reverse(bwmask_camera ~= 0) = 0;
bwmask_camera_reverse(bwmask_camera == 0) = 255;
bwmask_camera_reverse = uint8(bwmask_camera_reverse);

% Save mask
imwrite(bwmask_DMD, fullfile(createpath,'2_bwmask_DMD.bmp'));
imwrite(bwmask_DMD, fullfile(createpath,'2_bwmask_DMD2.bmp'));
imwrite(bwmask_DMD_reverse, fullfile(createpath,'4_bwmask_DMD_reverse.bmp'));
imwrite(bwmask_DMD_reverse, fullfile(createpath,'4_bwmask_DMD_reverse2.bmp'));

imwrite(bwmask_camera, fullfile(createpath,'3_bwmask_camera.tif'));
imwrite(bwmask_camera, fullfile(createpath,'3_bwmask_camera.png'));
imwrite(bwmask_camera_reverse, fullfile(createpath,'5_bwmask_camera_reverse.tif'));
imwrite(bwmask_camera_reverse, fullfile(createpath,'5_bwmask_camera_reverse.png'));

fprintf('Masks generated\n')

%%

% point convert. will generate blank pixels


% view_image = 'E:\1_Data\LRJ\20240907\granule1_mask.tif';
% view = double(imread(view_image));
% bwmask_camera = double(view>0);
%
% % create save file
% [imagepath,imagename] = fileparts(view_image);
% createpath = fullfile(imagepath,imagename);
% mkdir(createpath);
% fig_filename = fullfile(createpath, '1_selectedROI.fig');
% png_filename = fullfile(createpath, '1_selectedROI.png');
% saveas(gcf, fig_filename, 'fig');
% saveas(gcf, png_filename, 'png');
% save_path_rois = fullfile(createpath,'eachROI');
% save_path_rois_8bit = fullfile(createpath,'eachROI','8bit');
% mkdir(save_path_rois);
% mkdir(save_path_rois_8bit);
%
%
% npoints = sum(bwmask_camera(:)); % Convert points to homogeneous coordinates
% [row, col] = find(bwmask_camera == 1);
% positions = [col, row];
%
% points_homogeneous = [positions, ones(npoints, 1)]; % Nx3 matrix
% transformed_points_homogeneous = (T * points_homogeneous')';  % Perform affine transformation
% transformed_points = transformed_points_homogeneous(:, 1:2);  % Convert back to Cartesian coordinates
%
%
% mask = zeros(dmd_height,dmd_width);
% mask(sub2ind([dmd_height,dmd_width], round(transformed_points(:, 1)),round(transformed_points(:, 2))))= 1 ;
%
% bwmask_DMD(mask>0) = 1;
%
% % save as 8bit file
% mask = uint8(mask*255);
% imwrite(mask, fullfile(save_path_rois_8bit,sprintf('ROI 1.bmp')));
