package plugin.anatomical;

import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;

import com.squareup.picasso.Picasso;

/**
 * Created by graysonsharpe on 3/29/17.
 */

public interface OnImageDownloadListener {
    void onBitmapLoaded(final Bitmap bitmap, Picasso.LoadedFrom from);
    void onBitmapFailed(Drawable errorDrawable);
}
