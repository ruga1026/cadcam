%% 평면 상승 및 레이어별 데이터 저장

% 'region_1.mat' 파일 존재 여부 확인
if ~isfile('region_1.mat')
    error('파일 region_1.mat이 존재하지 않습니다. 먼저 초기 데이터를 처리하여 저장하십시오.');
end

% 'region_1.mat' 파일 로드
load('region_1.mat', 'below_all');

% 'below_all' 변수 존재 여부 확인
if ~exist('below_all', 'var')
    error('region_1.mat 파일에 변수 below_all이 존재하지 않습니다.');
end

% 평면 파라미터 설정 (슬라이싱용, 기울기 부호 양수)
angle = deg2rad(60);       % 각도를 라디안으로 변환
slope_x = tan(angle);      % x방향 기울기 계산 (부호 양수)
x_0 = 10;                  % 평면 방정식의 x0 값

% 평면 상승 및 -x 방향 이동 설정
% t = 0.4898; 레이어 수 772
t = 0.783; % 레이어 수 483
% t = 0.2;
delta_z = t / cosd(60);                % 평면을 상승시키는 단계 크기 (단위: z축의 단위와 동일)
delta_x = t * sind(60);                % 평면을 -x 방향으로 이동시키는 단계 크기
max_iterations = 2000;                   % 최대 반복 횟수 (무한 루프 방지)
current_z_offset = 0;                    % 현재 평면의 추가 높이
current_x_shift = 0;                     % 현재 평면의 x 방향 추가 이동

% 평면 위치 기록용 구조체 배열 초기화
plane_positions = struct('layer_num', {}, 'z_offset', {}, 'x_shift', {});

% 초기화
remaining_points = below_all;            % 아직 레이어에 할당되지 않은 포인트
layers = {};                             % 레이어를 저장할 셀 배열
layer_num = 1;                           % 레이어 번호 초기화

% 총 포인트 수
total_points = size(remaining_points, 1);
fprintf('총 평면 아래 포인트 수: %d\n', total_points);

%% 최초 평면 시각화

% 초기 평면의 z 값 계산
initial_plane_z = slope_x * (remaining_points(:,1) + x_0 + current_x_shift) + current_z_offset;

% x와 y의 범위를 설정
x_min = min(remaining_points(:,1));
x_max = max(remaining_points(:,1));
y_min = min(remaining_points(:,2));
y_max = max(remaining_points(:,2));

% 그리드 생성
[X0, Y0] = meshgrid(linspace(x_min, x_max, 100), linspace(y_min, y_max, 100));
Z0 = slope_x * (X0 + x_0 + current_x_shift) + current_z_offset;

% % 초기 평면과 모든 포인트 시각화
% figure;
% hold on;
% grid on;
% xlabel('X');
% ylabel('Y');
% zlabel('Z');
% title('이동 전 초기 평면과 포인트');

% % 모든 포인트 시각화 (예: 파란색)
% scatter3(remaining_points(:,1), remaining_points(:,2), remaining_points(:,3), 1, 'b', 'DisplayName', '포인트');
% 
% % 초기 평면 시각화
% surf(X0, Y0, Z0, 'FaceAlpha', 0.5, 'EdgeColor', 'none', 'FaceColor', [0.8 0.8 0.8], 'DisplayName', '초기 평면');
% 
% % 범례 추가
% legend('show');
% 
% hold off;
% 
% % 일시정지하여 그래프 확인
% pause(1);

%% 레이어 할당 루프

% 레이어 할당 루프
while ~isempty(remaining_points) && layer_num <= max_iterations
    
    % 평면 상승 및 -x 방향 이동
    current_z_offset = current_z_offset + delta_z;
    current_x_shift = current_x_shift - delta_x;  % -x 방향으로 이동

    % 현재 평면의 z 값 계산
    plane_z = slope_x * (remaining_points(:,1) + x_0 + current_x_shift) + current_z_offset;

    % 평면 아래로 내려오는 포인트 찾기
    points_below = remaining_points(:,3) < plane_z;

    % 현재 레이어에 할당할 포인트
    layer_points = remaining_points(points_below, :);

    % 현재 평면 위치 기록
    plane_positions(layer_num).layer_num = layer_num;
    plane_positions(layer_num).z_offset = current_z_offset;
    plane_positions(layer_num).x_shift = current_x_shift;

    % 레이어가 비어있지 않은 경우에만 저장
    if ~isempty(layer_points)
        % 레이어 저장 (셀 배열에 추가)
        layers{layer_num} = layer_points;
        fprintf('레이어 %d: %d 포인트를 할당했습니다.\n', layer_num, size(layer_points,1));

        % % 여기서 시각화 코드를 추가합니다.
        % % 평면과 현재 레이어 포인트를 시각화
        % figure;
        % hold on;
        % grid on;
        % xlabel('X');
        % ylabel('Y');
        % zlabel('Z');
        % title(sprintf('레이어 %d 및 사용된 평면', layer_num));
        % 
        % % 레이어 포인트 시각화 (예: 녹색)
        % scatter3(layer_points(:,1), layer_points(:,2), layer_points(:,3), 1, 'g', 'DisplayName', sprintf('레이어 %d 포인트', layer_num));
        % 
        % % 현재 평면 시각화
        % % x와 y의 범위를 설정 (남은 포인트 기준)
        % x_min = min(remaining_points(:,1));
        % x_max = max(remaining_points(:,1));
        % y_min = min(remaining_points(:,2));
        % y_max = max(remaining_points(:,2));
        % 
        % % 그리드 생성
        % [X, Y] = meshgrid(linspace(x_min, x_max, 100), linspace(y_min, y_max, 100));
        % Z = slope_x * (X + x_0 + current_x_shift) + current_z_offset;
        % 
        % % 평면을 반투명한 색으로 표시
        % surf(X, Y, Z, 'FaceAlpha', 0.5, 'EdgeColor', 'none', 'FaceColor', [0.5 0.5 0.5], 'DisplayName', '슬라이싱 평면');
        % 
        % % 범례 추가
        % legend('show');
        % 
        % hold off;

        % 레이어 번호 증가
        layer_num = layer_num + 1;

        % 할당된 포인트를 remaining_points에서 제거
        remaining_points(points_below, :) = [];

        % 진행 상황 출력
        fprintf('남은 포인트 수: %d\n', size(remaining_points, 1));

        % 디버깅: 현재 평면 위치 출력
        fprintf('현재 평면 위치 - z_offset: %.2f, x_shift: %.2f\n', current_z_offset, current_x_shift);

        % % 잠시 일시정지하여 그래프 확인 (필요 시 주석 처리)
        % pause(0.5);

    % else
    %     % 현재 레이어에 할당할 포인트가 없는 경우, 평면 상승을 멈춤
    %     fprintf('레이어 %d: 할당할 포인트가 없습니다. 평면 상승을 종료합니다.\n', layer_num);
    %     break;
    end
end

% 최대 반복 횟수 초과 시 경고
if layer_num > max_iterations
    warning('레이어 할당이 최대 반복 횟수(%d)를 초과했습니다. 일부 포인트가 할당되지 않았을 수 있습니다.', max_iterations);
end

% 모든 포인트가 할당되었는지 확인
if isempty(remaining_points)
    fprintf('모든 포인트가 레이어에 성공적으로 할당되었습니다.\n');
else
    fprintf('일부 포인트가 레이어에 할당되지 않았습니다. 남은 포인트 수: %d\n', size(remaining_points, 1));
end

%% 전체 레이어 저장 및 평면 위치 저장

% 레이어와 평면 위치를 'region1_layers.mat' 파일로 저장
if ~isempty(layers)
    save('region1_layers.mat', 'layers', 'plane_positions');
    fprintf('모든 레이어와 평면 위치를 region1_layers.mat 파일로 저장했습니다.\n');
else
    warning('저장할 레이어가 없습니다.');
end
