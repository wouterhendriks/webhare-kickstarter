import './forms.scss';

import * as forms from '@mod-publisher/js/forms';

forms.setup( { validate: true } );

import UploadField from '@mod-publisher/js/forms/fields/upload';
import ImgEditField from '@mod-publisher/js/forms/fields/imgedit';
import RTDField from '@mod-publisher/js/forms/fields/rtd';

dompack.register(".wh-form__upload", node => new UploadField(node));
dompack.register(".wh-form__imgedit", node => new ImgEditField(node));
dompack.register(".wh-form__rtd", node => new RTDField(node));
