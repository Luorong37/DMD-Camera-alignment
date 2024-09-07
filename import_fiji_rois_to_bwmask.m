function result = import_fiji_rois_to_bwmask(roi_folder, save_folder, image_size)
    % roi_folder: 包含 ROI 文件的文件夹路径
    % image_size: 图像的尺寸 [M, N]
    % 初始化空的 bwmask 矩阵
    bwmask = zeros(image_size);

    % 初始化空的 roi_positions 列表
    roi_positions = {};

    % 获取 ROI 文件列表
    roi_files = dir(fullfile(roi_folder, '*.roi'));
    
    % 加载每个 ROI 文件并生成掩膜
    for i = 1:length(roi_files)
        % 读取当前 ROI 文件
        roi_path = fullfile(roi_folder, roi_files(i).name);
        roi_struct = ReadImageJROI(roi_path);

        % 将 ROI 转换为二值掩膜
        switch lower(roi_struct.strType)
            case 'rectangle'
                mask = false(image_size);
                roi_struct.vnRectBounds = roi_struct.vnRectBounds + 1;
                mask(roi_struct.vnRectBounds(1):roi_struct.vnRectBounds(3), roi_struct.vnRectBounds(2):roi_struct.vnRectBounds(4)) = true;
                
                % 保存矩形的位置信息
                roi_positions{i} = roi_struct.vnRectBounds;

            case 'oval'
                mask = ellipse2mask('bounds', image_size, roi_struct.vnRectBounds + 1);
                
                % 保存椭圆的位置信息
                roi_positions{i} = roi_struct.vnRectBounds;

            case {'polygon', 'freehand'}
                mask = poly2mask(roi_struct.mnCoordinates(:, 1) + 1, roi_struct.mnCoordinates(:, 2) + 1, image_size(1), image_size(2));
                
                % 保存多边形的顶点位置信息
                roi_positions{i} = roi_struct.mnCoordinates;

            case 'traced'
                % 对于 Traced 类型的 ROI，也将使用 poly2mask 来生成掩膜
                mask = poly2mask(roi_struct.mnCoordinates(:, 1) + 1, roi_struct.mnCoordinates(:, 2) + 1, image_size(1), image_size(2));

                % 保存 traced 的顶点位置信息
                roi_positions{i} = roi_struct.mnCoordinates;

            otherwise
                warning('Unsupported ROI type: %s. Skipping...', roi_struct.strType);
                continue;
        end

        % 将掩膜添加到 bwmask 中，使用 i 作为标签
        bwmask(mask) = i;
    end

    % 将 bwmask 和 roi_positions 保存到结构体中
    result.bwmask = bwmask;
    result.Position = roi_positions;

    % 保存结果到文件
    save(fullfile(save_folder, '1_raw_ROI.mat'), 'result');

    fprintf('bwmask 和 ROI 位置信息已成功生成。\n');
end
