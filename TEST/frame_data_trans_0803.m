% ͼ���ע���������������

data = load('frame_data/1�ϲ���Ľ��.txt');

index_frame = data(:, 1);
start_index = min(index_frame);
max_index = max(index_frame);

NUM = length(index_frame);

for i = 1:NUM
    lane_data(index_frame(i), :) = data(i, :);
    
end

save frame_data/lane_data_1.mat lane_data