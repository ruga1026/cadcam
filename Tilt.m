% MATLAB 코드: 레이저 시각화 통합 및 도형 회전 예시

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. 데이터 로드 및 초기 설정
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 데이터 파일 이름
data_file_1 = 'housing_data.mat';

% 데이터 파일 존재 여부 확인
if ~isfile(data_file_1)
    error('파일 %s이 존재하지 않습니다.', data_file_1);
end

% 데이터 로드: 필요한 변수만 로드
load(data_file_1, 'G1_coords');

% 'G1_coords' 변수 존재 여부 및 크기 확인
if ~exist('G1_coords', 'var')
    error('변수 G1_coords가 %s 파일에 존재하지 않습니다.', data_file_1);
end

% 좌표 데이터 할당
coordinates = G1_coords;  % Size: (1761275 x 3)
clear G1_coords;          % 메모리 절약을 위해 원본 변수 삭제

% x, y, z 좌표 분리
x = coordinates(:,1);
y = coordinates(:,2);
z = coordinates(:,3);

% 데이터 행렬 생성
data = [x, y, z];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. 도형 회전 (x축 방향으로 60도)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 회전 각도 설정 (60도)
theta_deg = 60;
theta_rad = deg2rad(theta_deg);

% x축 회전 행렬 정의
R_x = [1, 0, 0;
       0, cos(theta_rad), -sin(theta_rad);
       0, sin(theta_rad),  cos(theta_rad)];

% 데이터 회전
rotated_coords = (R_x * data')';  % 각 행을 회전
rotated_x = rotated_coords(:,1);
rotated_y = rotated_coords(:,2);
rotated_z = rotated_coords(:,3);

% 회전된 데이터 행렬 생성
rotated_data = [rotated_x, rotated_y, rotated_z];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. 레이어 분할 (710 layers along rotated z-axis)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 레이어 수 유지: 710
num_layers = 710;
disp(['총 레이어 수: ', num2str(num_layers)]);

% 컬러맵 생성 (예: jet, parula, hsv 등 선택 가능)
cmap = jet(num_layers); % 'jet' 컬러맵 사용
colors = cmap;          % 각 레이어에 고유한 색상 할당

% 레이어를 저장할 셀 배열 초기화
layers = cell(num_layers, 1);

% 회전된 z 좌표의 최소 및 최대 값
z_min_rot = min(rotated_z);
z_max_rot = max(rotated_z);

% 레이어 간격 계산
z_step = (z_max_rot - z_min_rot) / num_layers;

% 각 레이어에 해당하는 점들을 layers 셀 배열에 저장
for n = 1:num_layers
    lower_bound = z_min_rot + (n-1) * z_step;
    upper_bound = z_min_rot + n * z_step;
    layers{n} = rotated_data(rotated_z >= lower_bound & rotated_z < upper_bound, :);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4. 레이저 시각화 초기화
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 그래프 초기화
figure('Name', '레이어별 레이저 경로 시각화', 'NumberTitle', 'off');
hold on;
grid on;
xlabel('X');
ylabel('Y');
zlabel('Z');
title('레이어별 레이저 경로 시각화');
view(3); % 3D 보기 설정

% Renderer를 OpenGL로 설정하여 그래픽 성능 향상
set(gcf, 'Renderer', 'opengl');

% 전체 좌표의 축 범위를 설정
x_min_rot = min(rotated_x);
x_max_rot = max(rotated_x);
y_min_rot = min(rotated_y);
y_max_rot = max(rotated_y);
z_min_rot = min(rotated_z);
z_max_rot = max(rotated_z);
axis([x_min_rot x_max_rot y_min_rot y_max_rot z_min_rot z_max_rot]);

% 동일한 축 비율 설정
axis equal;

% 출발점 설정 (데이터 범위에 맞게 자동 설정)
% 예시: 중앙 위쪽에서 시작
start_point = [ (x_min_rot + x_max_rot)/2, (y_min_rot + y_max_rot)/2, z_max_rot * 1.2 ];

% 출발점 플로팅
plot3(start_point(1), start_point(2), start_point(3), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
text(start_point(1), start_point(2), start_point(3), ' 출발점', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');

% 레이저 Line 객체 초기화 (레이저 A: 빨간색, B: 초록색, C: 파란색)
laser_a_handle = plot3(NaN, NaN, NaN, 'r-', 'LineWidth', 2);
laser_b_handle = plot3(NaN, NaN, NaN, 'g-', 'LineWidth', 2);
laser_c_handle = plot3(NaN, NaN, NaN, 'b-', 'LineWidth', 2);

% 목적점 Marker 핸들 초기화 (레이저 A, B, C)
laser_a_point = plot3(NaN, NaN, NaN, 'ro', 'MarkerSize', 5, 'MarkerFaceColor', 'r');
laser_b_point = plot3(NaN, NaN, NaN, 'go', 'MarkerSize', 5, 'MarkerFaceColor', 'g');
laser_c_point = plot3(NaN, NaN, NaN, 'bo', 'MarkerSize', 5, 'MarkerFaceColor', 'b');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5. 레이저 경로 시각화 및 데이터 포인트 실시간 플로팅
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('레이저 시각화를 시작합니다.');

% 진행률 표시기 초기화
wb = waitbar(0, '레이저 시각화 진행 중...');
total_layers = num_layers;

% 동영상 저장 설정
video_filename = 'laser_animation_rotated.avi'; % 저장할 동영상 파일 이름
video_fps = 30;                          % 초당 프레임 수 설정
v = VideoWriter(video_filename);         % VideoWriter 객체 생성
v.FrameRate = video_fps;                 % 프레임 속도 설정
open(v);                                  % 동영상 파일 열기

% 레이어 순회
for n = 1:num_layers
    current_layer = layers{n};
    layer_color = colors(n, :);  % 현재 레이어의 색상 지정

    % 포인트 수가 부족한 경우 처리
    if size(current_layer, 1) < 3
        warning('레이어 %d (z = %.6f)에 포인트가 3개 미만입니다. 레이저 할당을 건너뜁니다.', n, sorted_z(n));
        continue;
    end

    % x-좌표 기준으로 정렬
    [~, sort_order] = sort(current_layer(:, 1), 'ascend');
    sorted_layer_points = current_layer(sort_order, :);

    % 포인트 수 계산
    num_points = size(sorted_layer_points, 1);

    % 1/3 및 2/3 위치의 인덱스 계산
    idx_1_3 = floor(num_points / 3);
    idx_2_3 = floor(2 * num_points / 3);

    % 레이저별 포인트 할당
    laser_a = sorted_layer_points(1:idx_1_3, :);           % 0 ~ 1/3
    laser_b = sorted_layer_points(idx_1_3+1:idx_2_3, :);  % 1/3 ~ 2/3
    laser_c = sorted_layer_points(idx_2_3+1:end, :);      % 2/3 ~ 1

    %% 레이저 A: 빨간색
    start_a = start_point;                                % 레이저 A의 시작점 (공통)
    end_a = laser_a(end, :);                             % 레이저 A의 목적점 (1/3 지점)

    %% 레이저 B: 초록색
    start_b = start_point;                                % 레이저 B의 시작점 (공통)
    end_b = laser_b(end, :);                             % 레이저 B의 목적점 (2/3 지점)

    %% 레이저 C: 파란색
    start_c = start_point;                                % 레이저 C의 시작점 (공통)
    end_c = laser_c(1, :);                               % 레이저 C의 목적점 (마지막 지점)

    %% 레이저 Line 객체 업데이트
    set(laser_a_handle, 'XData', [start_a(1), end_a(1)], ...
                        'YData', [start_a(2), end_a(2)], ...
                        'ZData', [start_a(3), end_a(3)], ...
                        'Color', 'r');

    set(laser_b_handle, 'XData', [start_b(1), end_b(1)], ...
                        'YData', [start_b(2), end_b(2)], ...
                        'ZData', [start_b(3), end_b(3)], ...
                        'Color', 'g');

    set(laser_c_handle, 'XData', [start_c(1), end_c(1)], ...
                        'YData', [start_c(2), end_c(2)], ...
                        'ZData', [start_c(3), end_c(3)], ...
                        'Color', 'b');

    %% 목적점 플로팅
    set(laser_a_point, 'XData', end_a(1), 'YData', end_a(2), 'ZData', end_a(3));
    set(laser_b_point, 'XData', end_b(1), 'YData', end_b(2), 'ZData', end_b(3));
    set(laser_c_point, 'XData', end_c(1), 'YData', end_c(2), 'ZData', end_c(3));

    %% 레이어의 모든 포인트를 시각화 (레이어 포인트를 시각적으로 표시)
    % 'plot3'을 사용하여 벡터화된 방식으로 빠르게 플로팅
    plot3(sorted_layer_points(:,1), sorted_layer_points(:,2), sorted_layer_points(:,3), ...
          '.', 'MarkerSize', 1, 'Color', layer_color);

    %% 그래프 업데이트 및 동영상 프레임 캡처
    drawnow limitrate;    % 그래픽 업데이트 효율화

    % 동영상 프레임 캡처 및 기록
    frame = getframe(gcf);    % 현재 Figure의 프레임 캡처
    writeVideo(v, frame);     % 캡처한 프레임을 동영상에 기록

    %% 진행률 업데이트
    waitbar(n / total_layers, wb, sprintf('레이저 시각화 진행 중... 레이어 %d / %d', n, total_layers));

    %% 애니메이션 속도 조절 (필요에 따라 조정)
    % pause(0.001); % 속도 개선을 위해 최소화 또는 제거
end

% 진행률 표시기 닫기
close(wb);

% 동영상 파일 닫기
close(v); % 동영상 파일을 닫아 저장 완료

% 레이저 시각화 완료 메시지
disp('레이저 경로 시각화가 완료되었습니다.');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 6. 결과 확인
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 완료 후 추가적인 시각화 요소를 원한다면 여기서 추가 가능합니다.
% 예: 최종 레이저 위치에 마커 추가, 추가 텍스트 등
