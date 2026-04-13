function y = generateDigitalSignal(type, f, fs, duration, varargin)
% generateDigitalSignal 生成用于DAQ DO口输出的二进制周期信号（列向量）
%   输出信号只包含0和1
%
%   y = generateDigitalSignal(type, f, fs, duration)
%   y = generateDigitalSignal(type, f, fs, duration, 'pulseWidth', pulseWidth)
%   y = generateDigitalSignal(type, f, fs, duration, 'pulseWidth', pulseWidth, 'phase', phase)
%
% 输入参数：
%   type: 信号类型，字符串，可选：
%         'square' - 方波（默认脉冲宽度为周期的一半）
%         'pulse'  - 脉冲波（可自定义脉冲宽度）
%         'clock'  - 时钟信号（每个周期一个脉冲）
%   f: 信号频率（Hz）
%   fs: 采样率（Hz）
%   duration: 信号持续时间（秒）
%   可选参数对：
%     'pulseWidth' - 脉冲宽度（秒），即高电平持续时间
%     'phase' - 相位（秒），信号起始延迟时间
%
% 输出参数：
%   y: 二进制数字信号，列向量，只包含0和1

% 检查必需参数
if nargin < 4
    error('至少需要4个参数：type, f, fs, duration');
end

% 解析可选参数
p = inputParser;
addParameter(p, 'pulseWidth', 1/(2*f), @(x) x > 0 && x <= 1/f); % 脉冲宽度，默认周期的一半
addParameter(p, 'phase', 0, @(x) x >= 0); % 相位延迟，默认0秒
parse(p, varargin{:});
pulseWidth = p.Results.pulseWidth;
phase = p.Results.phase;

% 验证输入参数
if ~ischar(type) && ~isstring(type)
    error('type 必须是字符串');
end
if ~isscalar(f) || f <= 0
    error('f 必须是正标量');
end
if ~isscalar(fs) || fs <= 0
    error('fs 必须是正标量');
end
if ~isscalar(duration) || duration <= 0
    error('duration 必须是正标量');
end
if pulseWidth > 1/f
    error('脉冲宽度必须小于等于周期（1/f）');
end

% 计算占空比（用于内部计算）
dutyCycle = pulseWidth * f;

% 采样点数
n = round(fs * duration);
if n < 1
    error('持续时间过短，无法生成信号');
end

% 生成时间向量（列向量），考虑相位延迟
t = (0:n-1)' / fs - phase;

% 根据信号类型生成二进制信号
switch lower(type)
    case {'square', 'pulse'}
        % 方波或脉冲波
        % 计算每个采样点对应的周期相位（0到1之间）
        phase_in_cycle = mod(f * t, 1);
        
        % 根据脉冲宽度生成信号
        % 如果相位小于占空比，输出1；否则输出0
        y = double(phase_in_cycle < dutyCycle);
        
    case 'clock'
        % 时钟信号：每个周期只有一个采样点为1
        % 计算周期数
        T = 1/f; % 周期长度
        num_cycles = floor((duration + phase) / T);
        
        % 初始化全0信号
        y = zeros(n, 1);
        
        % 在每个周期的开始处设置一个脉冲
        for i = 0:num_cycles-1
            % 考虑相位延迟后的脉冲位置
            pulse_time = i * T + phase;
            if pulse_time >= 0 && pulse_time < duration
                pulse_index = round(pulse_time * fs) + 1;
                if pulse_index <= n
                    y(pulse_index) = 1;
                end
            end
        end
        
    otherwise
        error('不支持的信号类型。支持的类型: square, pulse, clock');
end

% 确保输出为列向量且为双精度类型（适合DAQ输出）
y = double(y);
end