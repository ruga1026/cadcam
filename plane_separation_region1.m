% 데이터 파일 이름
data_file = 'housing_data.mat';

% 데이터 파일 존재 여부 확인
if ~isfile(data_file)
    error('파일 %s이 존재하지 않습니다.', data_file);
end

% 데이터 로드: 필요한 변수만 로드
load(data_file, 'G1_coords');

% 'G1_coords' 변수 존재 여부 및 크기 확인
if ~exist('G1_coords', 'var')
    error('변수 G1_coords가 %s 파일에 존재하지 않습니다.', data_file);
end

% 좌표 데이터 할당
coordinates = G1_coords;  % Size: (1761275 x 3)
clear G1_coords;          % 메모리 절약을 위해 원본 변수 삭제

%% x 좌표 shifting (중심값을 0으로)
x_mean = mean(coordinates(:,1));                    % x 좌표의 평균 계산
coordinates(:,1) = coordinates(:,1) - x_mean;       % x 좌표 shifting
fprintf('x 좌표의 평균을 %.4f에서 0으로 shifting했습니다.\n', x_mean);

%% 평면 나누기
angle = deg2rad(60);       % 각도를 라디안으로 변환
slope_x = -tan(angle);     % x방향 기울기 계산 (부호 음수 유지)
x_0 = 10;                  % 평면 방정식의 x0 값

% 평면 방정식 정의: z = slope_x * (x + x0)
% 이 평면은 x = -x0일 때 z = 0을 만족
plane_z = slope_x * (coordinates(:,1) + x_0);

% 평면 위 또는 위에 있는지 여부 판단
is_above = coordinates(:,3) >= plane_z;

% 평면 위의 포인트
above_plane = coordinates(is_above, :);

% 평면 아래의 포인트
below_plane = coordinates(~is_above, :);

% 결과 출력 (선택 사항)
fprintf('전체 데이터 포인트 수: %d\n', size(coordinates, 1));
fprintf('평면 위 또는 위에 있는 포인트 수: %d\n', size(above_plane, 1));
fprintf('평면 아래에 있는 포인트 수: %d\n', size(below_plane, 1));

%% 데이터 시각화

% 데이터 포인트 수가 많아 시각화가 느려질 수 있으므로 샘플링 비율 설정
sample_ratio = 0.01;  % 1% 샘플링

% 평면 위의 포인트 샘플링
num_above = size(above_plane, 1);
if num_above > 0
    K_above = max(floor(num_above * sample_ratio), 1);
    K_above = min(K_above, num_above);  % K는 num_above를 초과할 수 없음
    sample_idx_above = randperm(num_above, K_above);
    sampled_above = above_plane(sample_idx_above, :);
else
    sampled_above = [];
    warning('평면 위에 있는 포인트가 없습니다.');
end

% 평면 아래의 포인트 샘플링
num_below = size(below_plane, 1);
if num_below > 0
    K_below = max(floor(num_below * sample_ratio), 1);
    K_below = min(K_below, num_below);  % K는 num_below를 초과할 수 없음
    sample_idx_below = randperm(num_below, K_below);
    sampled_below = below_plane(sample_idx_below, :);
else
    sampled_below = [];
    warning('평면 아래에 있는 포인트가 없습니다.');
end

% 3D 플롯 생성
figure;
hold on;
grid on;
xlabel('X');
ylabel('Y');
zlabel('Z');
title('평면을 기준으로 나누어진 데이터 포인트');

% 평면 위의 포인트 (빨간색)
if ~isempty(sampled_above)
    scatter3(sampled_above(:,1), sampled_above(:,2), sampled_above(:,3), 1, 'r', 'DisplayName', '평면 위');
end

% 평면 아래의 포인트 (파란색)
if ~isempty(sampled_below)
    scatter3(sampled_below(:,1), sampled_below(:,2), sampled_below(:,3), 1, 'b', 'DisplayName', '평면 아래');
end

% 평면 그리기
% 평면을 시각화하기 위해 x와 y의 범위를 설정
x_min = min(coordinates(:,1));
x_max = max(coordinates(:,1));
y_min = min(coordinates(:,2));
y_max = max(coordinates(:,2));

% 그리드 생성
[X, Y] = meshgrid(linspace(x_min, x_max, 100), linspace(y_min, y_max, 100));
Z = slope_x * (X + x_0);  % 평면 방정식: z = slope_x * (x + x0)

% 평면을 반투명한 색으로 표시
surf(X, Y, Z, 'FaceAlpha', 0.5, 'EdgeColor', 'none', 'FaceColor', [0.5 0.5 0.5], 'DisplayName', '평면');

% x, y, z 축 범위 설정
xlim([-80, 80]);
ylim([y_min, y_max]);
zlim([0, 160]);

% 범례 추가
legend('show');

hold off;

% 인터랙티브 회전 활성화
rotate3d on;

%% 전체 데이터 처리

% 평면 위의 모든 포인트 할당
if num_above > 0
    above_all = above_plane;
else
    above_all = [];
    warning('평면 위에 있는 포인트가 없습니다.');
end

% 평면 아래의 모든 포인트 할당
if num_below > 0
    below_all = below_plane;
else
    below_all = [];
    warning('평면 아래에 있는 포인트가 없습니다.');
end

% 전체 데이터 포인트 수 출력
fprintf('전체 평면 위 포인트 수: %d\n', size(above_all, 1));
fprintf('전체 평면 아래 포인트 수: %d\n', size(below_all, 1));

%% 영역 데이터 저장

% below_all을 'region_1.mat' 파일로 저장
if ~isempty(below_all)
    save('region_1.mat', 'below_all');
    fprintf('평면 아래의 모든 포인트를 region_1.mat 파일로 저장했습니다.\n');
else
    warning('저장할 평면 아래의 포인트가 없습니다.');
end
