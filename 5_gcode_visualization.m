cd 'G:\KAU_2024\2학기\CADCAM\팀플\매트랩\시각화'
clc; clear; close all;

% G-code 파일 경로 설정
filename = 'combined_layered_output.txt'; % 실제 G-code 파일 이름으로 변경하세요

% 파일을 읽어 G-code 라인들을 셀 배열로 저장
fid = fopen(filename, 'r');
if fid == -1
    error('파일을 열 수 없습니다: %s', filename);
end
gcode_lines = textscan(fid, '%s', 'Delimiter', '\n');
gcode_lines = gcode_lines{1};
fclose(fid);

% 데이터 저장용 변수 초기화
layer_data = struct('coords', {}); % 빈 구조체 배열로 초기화
current_layer = 0;

% G-code 라인을 처리하며 레이어별로 데이터 저장
for i = 1:length(gcode_lines)
    line = strtrim(gcode_lines{i});
    % LAYER 정보 추출
    if contains(line, ';LAYER:')
        layer_match = regexp(line, ';LAYER:(\d+)', 'tokens');
        if ~isempty(layer_match)
            current_layer = str2double(layer_match{1}{1}) + 1; % MATLAB 인덱스는 1부터 시작하므로 +1
            if length(layer_data) < current_layer % 구조체 배열 확장
                layer_data(current_layer).coords = [];
            end
        end
    elseif startsWith(line, 'G1') % G1 명령 처리
        % X, Y, Z 값 추출
        X_match = regexp(line, 'X([-+]?\d*\.?\d+)', 'tokens');
        Y_match = regexp(line, 'Y([-+]?\d*\.?\d+)', 'tokens');
        Z_match = regexp(line, 'Z([-+]?\d*\.?\d+)', 'tokens');
        
        if ~isempty(X_match) && ~isempty(Y_match) && ~isempty(Z_match) && current_layer > 0
            X = str2double(X_match{1}{1});
            Y = str2double(Y_match{1}{1});
            Z = str2double(Z_match{1}{1});
            % 좌표 저장
            layer_data(current_layer).coords = [layer_data(current_layer).coords; X, Y, Z];
        end
    end
end


% 레이어별 데이터를 10개씩 묶어 시각화
% 레이어별 데이터를 10개씩 묶어 시각화
figure('Name', 'G-code Layer Visualization', 'NumberTitle', 'off');
hold on;
color_map = lines(10); % 색상 맵 생성 (최대 10개의 그룹)

% 최대 레이어 계산 (유효한 레이어만)
max_layer = find(arrayfun(@(x) ~isempty(x.coords), layer_data), 1, 'last');

% 10개씩 묶어서 하나의 플롯에 시각화
for layer_group_start = 1:5:max_layer
    layer_group_end = min(layer_group_start + 4, max_layer); % 그룹의 마지막 레이어
    group_color_index = mod(ceil(layer_group_start / 5) - 1, 5) + 1; % 색상 인덱스를 1~10으로 반복
    group_color = color_map(group_color_index, :); % 그룹 색상 선택
    
    % 그룹의 첫 번째 레이어로 범례 생성
    legend_displayed = false; % 범례가 이미 표시되었는지 확인
    
    for layer = layer_group_start:layer_group_end
        if ~isempty(layer_data(layer).coords)
            coords = layer_data(layer).coords;
            if ~legend_displayed
                % 범례는 그룹의 첫 번째 레이어에만 추가
                plot3(coords(:, 1), coords(:, 2), coords(:, 3), '.', 'Color', group_color, ...
                      'DisplayName', sprintf('Layer %d-%d', layer_group_start, layer_group_end));
                legend_displayed = true;
            else
                % 다른 레이어는 범례 없이 플롯
                plot3(coords(:, 1), coords(:, 2), coords(:, 3), '.', 'Color', group_color, ...
                      'HandleVisibility', 'off'); % 범례 제외
            end
        end
    end
end

% 플롯 설정
xlabel('X 좌표');
ylabel('Y 좌표');
zlabel('Z 좌표');
title('레이어별 3D 시각화 (10개 묶음)');
legend('show', 'Location', 'bestoutside');
grid on;
axis equal;
hold off;
