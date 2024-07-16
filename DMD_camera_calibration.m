%% DMD_calibrate
% powerd by Luorong Liu-Yang at 20240710

% This function performs the following tasks:
% 1. Sets up initial parameters for DMD and camera resolution.
% 2. Generates a standard grid photo and saves the calibration parameters.
% 3. Takes a photo with this grid, selects points on the image, and calculates a transformation matrix.
% 4. Generates a mask based on a selected region of interest (ROI) and applies the transformation matrix.

%% Pre Setting

% Pre setting of DMD and Camera
dmd_width = 1920;
dmd_height = 1080;
dmd_size = [dmd_height, dmd_width]; 
camera_width = 2304;
camera_height = 2304;
camera_size = [camera_height, camera_width]; 

% Pre generation of standard grid photo
savepath = 'C:\Users\DELL\Desktop\DMD\1 Code\DMD-Camera-alignment\test';
calipath = fullfile(savepath,'DMD calibration');
mkdir(calipath);
Standard_Matrix_generator(calipath);
load(fullfile(calipath,'0_Standard parameters.mat'));

%% Take a photo

% Now, images are generated onto savepath. Start the DMD and input images.
% Choose the taken photo under DMD with calibrate matrix by camera
selected_image = 'E:\0_Code\Luorong\DMD\workpath\standard2.tif';

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

% Open and display the image
im = imread(selected_image);
imshow(imadjust(im));
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
    npoints = size(rois.Position{i}, 1); % Convert points to homogeneous coordinates
    positions = rois.Position{i};
    
    points_homogeneous = [positions, ones(npoints, 1)]; % Nx3 matrix
    transformed_points_homogeneous = (T * points_homogeneous')';  % Perform affine transformation
    transformed_points = transformed_points_homogeneous(:, 1:2);  % Convert back to Cartesian coordinates

    % transform to mask
    mask = poly2mask( transformed_points(:, 2),transformed_points(:, 1),dmd_height,dmd_width);
    bwmask_DMD(mask) = i;
    
    % save as 8bit file
    mask = uint8(mask*255);
    imwrite(mask, fullfile(save_path_rois,sprintf('ROI %d.bmp', i)));
  
end

% make all ROI be same intensity
bwmask_DMD(bwmask_DMD ~= 0) = 255;
bwmask_DMD = uint8(bwmask_DMD);

% create a camera mask
bwmask_camera(bwmask_camera ~= 0) = 255;
bwmask_camera = uint8(bwmask_camera);

imwrite(bwmask_DMD, fullfile(createpath,'2_bwmask_DMD.bmp'));
imwrite(bwmask_DMD, fullfile(createpath,'2_bwmask_DMD2.bmp'));

imwrite(bwmask_camera, fullfile(createpath,'3_bwmask_camera.tif'));
imwrite(bwmask_camera, fullfile(createpath,'3_bwmask_camera.png'));
%%





