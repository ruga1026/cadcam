%% 레이어 데이터 로드 및 병합

% region1_layers.mat 파일 로드
if ~isfile('region1_layers.mat')
    error('파일 region1_layers.mat이 존재하지 않습니다.');
end
load('region1_layers.mat', 'layers');
region1_layers = layers;  % 변수명 통일
clear layers;

% region2_layers.mat 파일 로드
if ~isfile('region2_layers.mat')
    error('파일 region2_layers.mat이 존재하지 않습니다.');
end
load('region2_layers.mat', 'region2_layers');

% region3_layers.mat 파일 로드
if ~isfile('region3_layers.mat')
    error('파일 region3_layers.mat이 존재하지 않습니다.');
end
load('region3_layers.mat', 'region3_layers');

%% 레이어 배열들의 크기 확인 및 형식 통일

% 각 레이어 배열의 크기 출력
fprintf('region1_layers 크기: %s\n', mat2str(size(region1_layers)));
fprintf('region2_layers 크기: %s\n', mat2str(size(region2_layers)));
fprintf('region3_layers 크기: %s\n', mat2str(size(region3_layers)));

% region1_layers와 region3_layers가 행 벡터(1xN)인 경우 열 벡터(Nx1)로 변환
if isrow(region1_layers)
    region1_layers = region1_layers';
end
if isrow(region3_layers)
    region3_layers = region3_layers';
end

% 모든 레이어 배열이 열 벡터 형태의 셀 배열인지 확인
fprintf('변환 후 region1_layers 크기: %s\n', mat2str(size(region1_layers)));
fprintf('region2_layers 크기: %s\n', mat2str(size(region2_layers)));
fprintf('변환 후 region3_layers 크기: %s\n', mat2str(size(region3_layers)));

%% 최대 레이어 수 결정

% 각 지역의 레이어 수
num_layers_region1 = length(region1_layers);
num_layers_region2 = length(region2_layers);
num_layers_region3 = length(region3_layers);

% 최대 레이어 수
max_num_layers = max([num_layers_region1, num_layers_region2, num_layers_region3]);
fprintf('최대 레이어 수: %d\n', max_num_layers);

%% 레이어 번호별로 포인트 병합 및 별도 변수에 저장

% 레이어 번호별로 포인트를 병합할 셀 배열 초기화
combined_layers = cell(max_num_layers, 1);

% 각 영역별 레이어를 별도 변수에 저장할 셀 배열 초기화
region_layers = cell(max_num_layers, 3);  % 각 행은 레이어 번호, 열은 각 지역(1: region1, 2: region2, 3: region3)

for i = 1:max_num_layers
    % region1_layers에서 레이어 i의 포인트 추가
    if i <= num_layers_region1 && ~isempty(region1_layers{i})
        region_layers{i,1} = region1_layers{i};
    else
        region_layers{i,1} = [];
    end
    
    % region2_layers에서 레이어 i의 포인트 추가
    if i <= num_layers_region2 && ~isempty(region2_layers{i})
        region_layers{i,2} = region2_layers{i};
    else
        region_layers{i,2} = [];
    end
    
    % region3_layers에서 레이어 i의 포인트 추가
    if i <= num_layers_region3 && ~isempty(region3_layers{i})
        region_layers{i,3} = region3_layers{i};
    else
        region_layers{i,3} = [];
    end
    
    % 각 지역의 레이어 포인트를 병합하여 combined_layers에 저장
    combined_points = [region_layers{i,1}; region_layers{i,2}; region_layers{i,3}];
    combined_layers{i} = combined_points;
end

%% 결과 저장

% 각 레이어별로 별도 변수에 저장된 지역별 포인트를 저장
save('merged_layers.mat');
fprintf('각 레이어를 지역별로 분리하여 merged_layers.mat 파일로 저장했습니다.\n');

%% 레이어 정보 요약 출력

for i = 1:max_num_layers
    num_points_region1 = size(region_layers{i,1}, 1);
    num_points_region2 = size(region_layers{i,2}, 1);
    num_points_region3 = size(region_layers{i,3}, 1);
    total_points = size(combined_layers{i}, 1);
    fprintf('레이어 %d: Region1: %d 포인트, Region2: %d 포인트, Region3: %d 포인트, 총 %d 포인트\n', i, num_points_region1, num_points_region2, num_points_region3, total_points);
end
