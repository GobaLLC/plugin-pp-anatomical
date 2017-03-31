package plugin.anatomical;

import android.content.Context;
import android.content.ContextWrapper;
import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.os.Environment;

import com.squareup.picasso.Picasso;
import com.squareup.picasso.Target;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

/**
 * Created by graysonsharpe on 3/29/17.
 */

public class AnatomyImageDownloader {

    private static final String IMAGE_NAME = "image.jpg";

    private Context mContext;

    private OnImageDownloadListener mOnImageDownloadListener;

    private Target target;

    private AnatomyImage _anatomyImage;

    public AnatomyImageDownloader(Context context, AnatomyImage anatomyImage) {
        mContext = context;
        _anatomyImage = anatomyImage;
    }

    public void setOnImageDownloadListener(OnImageDownloadListener listener) {
        mOnImageDownloadListener = listener;
    }


    public void downloadImage() {
        target = new Target() {
            @Override
            public void onBitmapLoaded(final Bitmap bitmap, final Picasso.LoadedFrom from) {

                new Thread(new Runnable() {
                    @Override
                    public void run() {
//                    File[] fileName = {new File(folder, "one.jpg"), new File(folder, "two.jpg")};
//                        File sd = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES);
//                        File sd =  Environment.getExternalStorageDirectory();

                        ContextWrapper cw = new ContextWrapper(mContext);
                        String name_="foldername"; //Folder name in device android/data/
                        File sd = cw.getDir(name_, Context.MODE_PRIVATE);

                        String filePath = _anatomyImage.getFolderPath() + "/" + IMAGE_NAME;
                        File targetFile = new File(sd, filePath);
                        File parent = targetFile.getParentFile();

                        if (!targetFile.exists()) {
                            try {
                                if (!parent.exists()) {
                                    parent.mkdirs();
                                }
                                targetFile.createNewFile();

                                FileOutputStream outputStream = new FileOutputStream(String.valueOf(targetFile));
                                bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);
                                outputStream.close();

                            } catch (IOException e) {
                                e.printStackTrace();
                            }
                        }
//                        else {
//
//                            try {
//                                FileOutputStream outputStream = new FileOutputStream(String.valueOf(targetFile));
//                                bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);
//                                outputStream.close();
//
//                            } catch (FileNotFoundException e) {
//                                e.printStackTrace();
//                            } catch (IOException e) {
//                                e.printStackTrace();
//                            }
//                        }

                        if (mOnImageDownloadListener != null)
                            mOnImageDownloadListener.onBitmapLoaded(bitmap, from);

                    }
                }).start();

            }

            @Override
            public void onBitmapFailed(Drawable errorDrawable) {
                if (mOnImageDownloadListener != null)
                    mOnImageDownloadListener.onBitmapFailed(errorDrawable);
            }

            @Override
            public void onPrepareLoad(Drawable placeHolderDrawable) {

            }
        };

        Picasso.with(mContext.getApplicationContext()).load(_anatomyImage.getSourceUrl()).into(target);

    }

}
