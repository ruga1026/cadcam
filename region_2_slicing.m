%% region_2 데이터 로드

% 'region2_layers.mat' 파일 존재 여부 확인
if ~isfile('region2_layers.mat')
    error('파일 region2_layers.mat이 존재하지 않습니다. 먼저 데이터를 처리하여 region_2를 생성하십시오.');
end

% 'region2_layers.mat' 파일 로드
load('region2_layers.mat', 'region_2_points');

% 'region_2_points' 변수 존재 여부 확인
if ~exist('region_2_points', 'var')
    error('region2_layers.mat 파일에 변수 region_2_points가 존재하지 않습니다.');
end

%% 레이어 슬라이싱 및 저장

% delta_z 설정 (레이어 두께)
delta_z = 0.2;

% z 좌표의 최소값과 최대값 찾기
z_min = min(region_2_points(:,3));
z_max = max(region_2_points(:,3));

% 레이어 경계값 생성
layer_edges = z_min : delta_z : z_max + delta_z;  % 마지막 레이어를 포함하기 위해 + delta_z

% 레이어 수
num_layers = length(layer_edges) - 1;

% 레이어를 저장할 셀 배열 초기화
layers = cell(num_layers, 1);

% 남은 포인트 초기화
remaining_points = region_2_points;

% 레이어 할당 루프
for i = 1:num_layers
    z_lower = layer_edges(i);
    z_upper = layer_edges(i+1);
    
    % 현재 레이어에 속하는 포인트 찾기
    in_layer = remaining_points(:,3) >= z_lower & remaining_points(:,3) < z_upper;
    layer_points = remaining_points(in_layer, :);
    
    % 레이어에 포인트가 있는 경우에만 저장
    if ~isempty(layer_points)
        layers{i} = layer_points;
        fprintf('레이어 %d: %d 포인트를 할당했습니다. (z 범위: %.2f ~ %.2f)\n', i, size(layer_points,1), z_lower, z_upper);
        
        % 할당된 포인트를 remaining_points에서 제거
        remaining_points(in_layer, :) = [];
    else
        fprintf('레이어 %d: 할당할 포인트가 없습니다. (z 범위: %.2f ~ %.2f)\n', i, z_lower, z_upper);
    end
end

% 전체 레이어 수 출력
fprintf('총 %d개의 레이어가 생성되었습니다.\n', num_layers);

% 남은 포인트가 있는지 확인
if ~isempty(remaining_points)
    fprintf('일부 포인트가 레이어에 할당되지 않았습니다. 남은 포인트 수: %d\n', size(remaining_points, 1));
else
    fprintf('모든 포인트가 레이어에 성공적으로 할당되었습니다.\n');
end

%% 결과 저장
region2_layers = layers;
% 'region2_layers.mat' 파일로 저장
save('region2_layers.mat', 'region2_layers');
fprintf('모든 레이어를 region2_layers.mat 파일로 저장했습니다.\n');

%% 레이어 정보 요약 출력

% 각 레이어의 포인트 수 출력
for i = 1:num_layers
    if ~isempty(layers{i})
        fprintf('레이어 %d: %d 포인트\n', i, size(layers{i},1));
    end
end
