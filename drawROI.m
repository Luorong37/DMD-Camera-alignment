function [rois] = drawROI(image)
%
%  image ： array
%
%
%

figure();
fig = gcf;
set(gcf, 'KeyPressFcn', @(src, event) set_space_pressed(event, fig));


imshow(imadjust(image));
title(sprintf('Press SPACE to continue, Press ENTER to end'));

bwmask = zeros(size(image));
nroi = 0;
rois = struct();
rois.Position = {};
rois.boundary = {};

while true
    % select ROI
    nroi = max(bwmask(:)) + 1;
    roi = drawpolygon();
    mask = poly2mask(roi.Position(:, 1), roi.Position(:, 2), size(image, 1), size(image, 2));
    bwmask(mask) = nroi;

    rois.Position{end+1} = roi.Position;
    boundary = bwboundaries(mask);
    boundary = boundary{1};
    rois.boundary{end+1} = boundary;

    % 标注ROI编号
    text(mean(boundary(:, 2)), mean(boundary(:, 1)), num2str(nroi), 'Color', 'k', 'FontSize', 12 ); hold on;

    % Wait for user input
    fig.UserData = [];
    waitfor(fig, 'UserData');
    if strcmp(fig.UserData, 'stop')
        break;
    elseif strcmp(fig.UserData, 'spacePressed')
        continue;
    end
end

% save
rois.bwmask = bwmask;
rois.number = nroi;

fprintf('Finished ROI selection\n');
end


function set_space_pressed(event, fig)
if strcmp(event.Key, 'space')
    fig.UserData = 'spacePressed';
elseif strcmp(event.Key, 'return')
    fig.UserData = 'stop';
end
end