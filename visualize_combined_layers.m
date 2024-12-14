%% 병합된 레이어 데이터 로드

% 'combined_layers.mat' 파일 존재 여부 확인
if ~isfile('merged_layers.mat')
    error('파일 merged_layers.mat이 존재하지 않습니다.');
end

% 'combined_layers.mat' 파일 로드
load('merged_layers.mat');

%% 레이어 번호별로 포인트 병합

% 레이어 번호별로 포인트를 병합할 셀 배열 초기화
combined_layers = cell(max_num_layers, 1);

for i = 1:max_num_layers
    % 현재 레이어의 포인트를 저장할 변수 초기화
    layer_points = [];
    
    % region1_layers에서 레이어 i의 포인트 추가
    if i <= num_layers_region1 && ~isempty(region1_layers{i})
        layer_points = [layer_points; region1_layers{i}];
    end
    
    % region2_layers에서 레이어 i의 포인트 추가
    if i <= num_layers_region2 && ~isempty(region2_layers{i})
        layer_points = [layer_points; region2_layers{i}];
    end
    
    % region3_layers에서 레이어 i의 포인트 추가
    if i <= num_layers_region3 && ~isempty(region3_layers{i})
        layer_points = [layer_points; region3_layers{i}];
    end
    
    % 병합된 포인트를 combined_layers에 저장
    if ~isempty(layer_points)
        combined_layers{i} = layer_points;
    else
        combined_layers{i} = [];
    end
end
save('combined_layers.mat', 'combined_layers')

%% 레이어 시각화

% 레이어 수 확인
num_layers = length(combined_layers);
fprintf('총 레이어 수: %d\n', num_layers);

% % 색상 맵 생성 (레이어 수에 맞게 조정)
% % 레이어 수가 많을 경우, 색상을 반복하여 사용
% num_colors = 20;  % 사용할 색상 수
% cmap = lines(num_colors);  % lines 색상 맵 사용
% 
% % 3D 플롯 생성
% figure;
% hold on;
% grid on;
% xlabel('X');
% ylabel('Y');
% zlabel('Z');
% title('병합된 레이어 시각화 (같은 레이어는 같은 색상)');
% 
% % 각 레이어를 순회하며 시각화
% for i = 1:num_layers
%     layer_points = combined_layers{i};
%     if ~isempty(layer_points)
%         % 색상 인덱스 계산 (색상이 반복되도록)
%         color_idx = mod(i-1, num_colors) + 1;
%         color = cmap(color_idx, :);
% 
%         % 레이어 포인트 시각화
%         scatter3(layer_points(:,1), layer_points(:,2), layer_points(:,3), 1, 'MarkerEdgeColor', color, 'DisplayName', sprintf('레이어 %d', i));
%     end
% end
% 
% % 범례 추가 (레이어 수가 많을 경우 범례를 생략하거나 제한)
% if num_layers <= 20
%     legend('show');
% else
%     legend off;  % 레이어 수가 많으면 범례를 표시하지 않음
% end
% 
% hold off;
% 
% % 인터랙티브 회전 활성화
% rotate3d on;

%% 시각화 옵션 조정 (필요 시)

% 레이어 수가 많아 색상이 구분되지 않을 경우, 레이어를 그룹화하여 시각화할 수 있습니다.

% 예를 들어, 레이어를 그룹화하여 10개 그룹으로 나누기
num_groups = 40;
layers_per_group = ceil(num_layers / num_groups);

cmap = lines(num_groups);

figure;
hold on;
grid on;
xlabel('X');
ylabel('Y');
zlabel('Z');
title('레이어 그룹화 시각화');

for i = 1:num_layers
    layer_points = combined_layers{i};
    if ~isempty(layer_points)
        % 그룹 인덱스 계산
        group_idx = ceil(i / layers_per_group);
        color = cmap(group_idx, :);
        
        % 레이어 포인트 시각화
        scatter3(layer_points(:,1), layer_points(:,2), layer_points(:,3), 1, 'MarkerEdgeColor', color);
    end
end

xlim([-80, 80]);
zlim([0, 160]);

hold off;
rotate3d on;
