function aligned = align_ant(image)

refArea = 1300;

% to grayscale 
a = min(image,[],3);

% contrast adjustment
a = imadjust(a);

% sharpening
a = imsharpen(a);

% threshold
a = a<128;

% some morphological filtering

a = imclose(imopen(a,ones(5)),ones(5));
a = bwareafilt(a,1);

% rotate by 90
a = imrotate(a,-90);

% get aligment parameters
S = regionprops(a,'Centroid','Area','Orientation');
center = size(image)/2;
shift = center(1:2) - S.Centroid;
rot = -S.Orientation;
scale = sqrt(refArea/S.Area);


% align image
aligned = imtranslate(image,shift,'FillValues',squeeze(image(1,1,:)));
aligned = imcomplement(imrotate(imcomplement(aligned),rot,'bilinear','crop'));
aligned = imresize(aligned,scale);

% scale image
if scale>1
    s = size(aligned);
    s1 = size(image);
    ds = s-s1;
    aligned = imcrop(aligned,[floor(ds(1:2)/2),s1(1:2)]);
    aligned = aligned(1:s1(1),1:s1(2),:);
elseif scale<1
    s = size(image)-size(aligned);
    p1 = floor(s(1:2)/2);
    p2 = s(1:2) - p1;
    aligned = padarray(aligned,[p1,0],aligned(1,1),'pre');
    aligned = padarray(aligned,[p2,0],aligned(1,1),'post');
end
   









