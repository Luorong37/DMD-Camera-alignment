function [rois] = drawROI(image)
% show image
figure();
fig = gcf;
set(fig, 'KeyPressFcn', @(src, event) set_key_pressed(event, fig));
imshow(imadjust(image));
t = title(sprintf('click points for a polygon. right click as end\nPress SPACE to continue,Press ENTER to end,Press r to reselect'));
set(fig,'Position',get(0,'Screensize'))

bwmask = zeros(size(image));
nroi = 0;
rois = struct();
rois.Position = {};
rois.boundary = {};
key = '';

while true
    % select ROI
    nroi = max(bwmask(:)) + 1;
    roi = drawpolygon();
    mask = poly2mask(roi.Position(:, 1), roi.Position(:, 2), size(image, 1), size(image, 2));
    boundary = bwboundaries(mask);
    boundary = boundary{1};

    % store roi
    bwmask(mask) = nroi;
    rois.boundary{end+1} = boundary;
    rois.Position{end+1} = roi.Position;

    % 标注ROI编号
    number = text(mean(boundary(:, 2)), mean(boundary(:, 1)), num2str(nroi), 'Color', 'k', 'FontSize', 12 ); hold on;

    % Wait for user input
    key = wait_for_key(fig);
    switch key
        case 'return'
            delete(t);
            break;
        case 'space'
            key = '';
            continue;
        case 'r'
            delete(roi);delete(number);
            bwmask(mask) = 0;
            if nroi > 1
                rois.boundary = rois.boundary{1:end-1};
                rois.Position = roi.Position{1:end-1};
            else
                rois.Position = {};
                rois.boundary = {};
            end
    end
end

% save
rois.bwmask = bwmask;
rois.number = nroi;
fprintf('Finished ROI selection\n');

end

    function set_key_pressed(event, fig)
        if any(strcmp(event.Key, {'space', 'return', 'v', 'r'}))
            fig.UserData.space = event.Key;
        end
    end

    function key = wait_for_key(fig)
        % Waits for a keypress event to continue or stop ROI selection
        fig.UserData.space = [];
        waitfor(fig, 'UserData');
        key = fig.UserData.space;
    end