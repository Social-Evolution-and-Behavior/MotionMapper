function antAlignment(Trck,inavi,outavi)

vr = VideoReader(inavi);
vw = VideoWriter(outavi);
fps = vr.FrameRate;
vw.FrameRate = fps;
open(vw);


[fpath,fname,fext]=fileparts(inavi);
s = strsplit(fname,'_');
m = str2num(s{3}(3:end));

[TRAJ,trjs]=Trck.loaddata(m);
trj = trjs.withName(fname);
or = trj.ORIENT;
i=0;
while hasFrame(vr)
    i=i+1;
    image=readFrame(vr);
    
    % convert to gry
    image=min(image,[],3);
    
    % some image adjustments
    image=imadjust(image);
    image=imsharpen(image);
    image=imcomplement(image);
    image=imfill(image,4);
    
    % align image
    image = imrotate(image,deg(or(i))+90,'bilinear','crop');
    im=imerode(image>128,ones(3));
    im=bwareafilt(im,1);
    try
    s=regionprops(im,'Extrema');
    top=min(s.Extrema(:,2));
    bottom = size(im,1)-max(s.Extrema(:,2));
    
    if top<bottom
        image=flipm(image,[1,2]);
    end
    catch
    end
        
    writeVideo(vw,image);
    
end

close(vw)





