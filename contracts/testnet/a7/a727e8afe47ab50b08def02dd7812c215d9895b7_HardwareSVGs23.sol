// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import '../../../interfaces/IHardwareSVGs.sol';
import '../../../interfaces/ICategories.sol';

/// @dev Experimenting with a contract that holds huuuge svg strings
contract HardwareSVGs23 is IHardwareSVGs, ICategories {
	function hardware_83() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Sextant',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientUnits="userSpaceOnUse" id="h83-a" x1="2" x2="2" y1="18"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h83-b" x1="0.5" x2="0.5" xlink:href="#h83-a" y1="4.22" y2="0"/><linearGradient gradientTransform="matrix(0, -1, -1, 0, 24638.64, 8217.6)" gradientUnits="userSpaceOnUse" id="h83-c" x1="8217.6" x2="8205.77" y1="24638.14" y2="24638.14"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h83-d" x1="6.82" x2="6.82" y1="7.07" y2="0.87"><stop offset="0" stop-color="gray"/><stop offset="0.24" stop-color="#4b4b4b"/><stop offset="0.68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientTransform="matrix(0, -1, -1, 0, 24638.31, 8217.28)" id="h83-e" x1="8217.28" x2="8207.1" xlink:href="#h83-c" y1="24637.06" y2="24637.06"/><filter id="h83-f" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient id="h83-g" x1="109.78" x2="109.78" xlink:href="#h83-d" y1="172.95" y2="169.28"/><linearGradient gradientUnits="userSpaceOnUse" id="h83-h" x1="110" x2="110" y1="92.23" y2="157.75"><stop offset="0" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h83-i" x1="93.76" x2="93.76" xlink:href="#h83-c" y1="102" y2="127.58"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h83-j" x1="82.95" x2="103.99" xlink:href="#h83-c" y1="114.67" y2="114.67"/><linearGradient gradientUnits="userSpaceOnUse" id="h83-k" x1="110" x2="110" y1="156.75" y2="91.23"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h83-l" x1="65.22" x2="154.78" xlink:href="#h83-k" y1="149.2" y2="149.2"/><linearGradient id="h83-m" x1="68.55" x2="151.45" xlink:href="#h83-a" y1="146.79" y2="146.79"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h83-n" x1="110" x2="110" xlink:href="#h83-c" y1="177.49" y2="92.39"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h83-o" x1="110" x2="110" xlink:href="#h83-c" y1="92.14" y2="177.74"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h83-p" x1="110" x2="110" xlink:href="#h83-c" y1="83.68" y2="96.32"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h83-q" x1="110" x2="110" xlink:href="#h83-c" y1="96.82" y2="83.18"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h83-r" x1="110" x2="110" xlink:href="#h83-c" y1="163.01" y2="153.02"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h83-s" x1="110" x2="110" xlink:href="#h83-c" y1="161.34" y2="154.69"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h83-t" x1="110" x2="110" xlink:href="#h83-c" y1="154.19" y2="161.84"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h83-u" x1="110" x2="110" xlink:href="#h83-c" y1="160.82" y2="155.18"/><symbol id="h83-w" viewBox="0 0 13.64 7.13"><rect fill="url(#h83-d)" height="7.13" width="13.64"/></symbol><symbol id="h83-v" viewBox="0 0 4 18"><polygon fill="url(#h83-a)" points="4 17 3.01 18 0.99 18 0 17 0 1 0.99 0 3.01 0 4 1 4 17"/><use height="7.13" transform="translate(0.99) scale(0.15 2.52)" width="13.64" xlink:href="#h83-w"/></symbol><symbol id="h83-ab" viewBox="0 0 1 4.22"><polygon fill="url(#h83-b)" points="0 0 0 4.22 1 3.23 1 1 0 0"/></symbol><symbol id="h83-ag" viewBox="0 0 1 11.83"><path d="M0,0,1,1v9.83l-1,1Z" fill="url(#h83-c)"/></symbol><symbol id="h83-af" viewBox="0 0 2 10.18"><path d="M1,0,2,.86V9.32l-1,.86L.5,5.09Z" fill="url(#h83-e)"/><use height="11.83" transform="translate(1 10.18) rotate(180) scale(1 0.86)" width="1" xlink:href="#h83-ag"/></symbol></defs><g filter="url(#h83-f)"><rect height="2.5" width="3" x="98.19" y="169.63"/><path d="M127.43,173H100.69v-4.23h26.74Zm-28.74-4.23H92.57l-.44,2.12.44,2.11h6.12Z" fill="url(#h83-g)"/><path d="M124,116.24,90.18,156.79M96,116.24l33.78,40.55M101.67,108l37.5,45m-20.84-45-37.5,45M110,93,77,148m33-55,33,55" fill="none" stroke="url(#h83-h)" stroke-miterlimit="10" stroke-width="3"/><polyline fill="url(#h83-i)" points="103.99 102 94.01 102 83.54 118.77 89.2 127.58" stroke="url(#h83-j)" stroke-miterlimit="10"/><path d="M124,115.24,90.18,155.79M96,115.24l33.78,40.55M101.67,107l37.5,45m-20.84-45-37.5,45M110,92,77,147m33-55,33,55" fill="none" stroke="url(#h83-k)" stroke-miterlimit="10" stroke-width="3"/><path d="M151.08,139.29a55.48,55.48,0,0,1-82.16,0" fill="none" stroke="url(#h83-l)" stroke-miterlimit="10" stroke-width="10"/><path d="M151.08,139.29a55.48,55.48,0,0,1-82.16,0m3.7-3.36a50.49,50.49,0,0,0,74.76,0" fill="none" stroke="url(#h83-m)" stroke-miterlimit="10"/><path d="M104.88,152l-2.41,23.31a1.92,1.92,0,0,0,1.91,2.14h11.24a1.92,1.92,0,0,0,1.91-2.14L115.12,152a1.66,1.66,0,0,1-1.66-1.72l2.15-57.93H104.39l2.15,57.93A1.66,1.66,0,0,1,104.88,152ZM110,121.92a2.22,2.22,0,0,1,2.22,2.28l-.92,25a1.3,1.3,0,0,1-2.6,0l-.92-25A2.22,2.22,0,0,1,110,121.92Z" fill="url(#h83-n)" stroke="url(#h83-o)" stroke-miterlimit="10" stroke-width="0.5"/><polygon points="124.42 106.88 110 106.88 108.99 104.04 124.42 103 124.42 106.88"/><path d="M110,96.32A6.32,6.32,0,1,1,116.32,90,6.32,6.32,0,0,1,110,96.32Z" fill="url(#h83-p)" stroke="url(#h83-q)" stroke-miterlimit="10"/><circle cx="110" cy="158.02" fill="none" r="3.99" stroke="url(#h83-r)" stroke-miterlimit="10" stroke-width="2"/><circle cx="110" cy="158.02" fill="url(#h83-s)" r="3.33" stroke="url(#h83-t)" stroke-miterlimit="10"/><use height="18" transform="translate(108.28 82.56) scale(0.86 0.83)" width="4" xlink:href="#h83-v"/><use height="18" transform="matrix(0.78, -0.63, 0.63, 0.78, 77.81, 96.23)" width="4" xlink:href="#h83-v"/><use height="18" transform="translate(77.81 116.23) rotate(-38.74)" width="4" xlink:href="#h83-v"/><use height="4.22" transform="translate(127.43 168.76)" width="1" xlink:href="#h83-ab"/><use height="4.22" transform="matrix(-1, 0, 0, 1, 92.57, 168.76)" width="1" xlink:href="#h83-ab"/><use height="7.13" transform="translate(134.5 98.93) scale(1.11 0.86)" width="13.64" xlink:href="#h83-w"/><use height="7.13" transform="translate(110 98.12) scale(1.87 1.09)" width="13.64" xlink:href="#h83-w"/><use height="10.18" transform="translate(134 96.91)" width="2" xlink:href="#h83-af"/><use height="10.18" transform="translate(148.64 97.38) scale(1 0.91)" width="2" xlink:href="#h83-af"/><use height="4.22" transform="matrix(-1, 0, 0, 1.84, 110, 98.12)" width="1" xlink:href="#h83-ab"/><line fill="url(#h83-u)" stroke="#000" stroke-miterlimit="10" stroke-width="0.5" x1="110" x2="110" y1="155.18" y2="160.82"/><use height="18" transform="translate(122.24 95.7) scale(0.86 0.7)" width="4" xlink:href="#h83-v"/></g>'
					)
				)
			);
	}

	function hardware_84() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Lyre',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientTransform="translate(16413.477 16327.688) rotate(180)" gradientUnits="userSpaceOnUse" id="h84-a" x1="16405.79" x2="16413.477" y1="16326.218" y2="16326.218"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="translate(16413.477 16327.688) rotate(180)" gradientUnits="userSpaceOnUse" id="h84-b" x1="16405.79" x2="16413.477" y1="16327.016" y2="16327.016"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><filter id="h84-c" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h84-d" x1="110" x2="110" xlink:href="#h84-a" y1="159.256" y2="99.397"/><linearGradient gradientUnits="userSpaceOnUse" id="h84-e" x1="91.113" x2="128.887" y1="102.5" y2="102.5"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="#696969"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h84-f" x1="91.113" x2="128.887" y1="101.5" y2="101.5"><stop offset="0" stop-color="#696969"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="#696969"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h84-g" x1="101.651" x2="118.417" xlink:href="#h84-b" y1="157.966" y2="157.966"/><linearGradient gradientUnits="userSpaceOnUse" id="h84-h" x1="110" x2="110" y1="87.044" y2="181.185"><stop offset="0" stop-color="#fff"/><stop offset="0.412" stop-color="gray"/><stop offset="0.715" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h84-i" x1="110.005" x2="110.005" y1="178.359" y2="82.499"><stop offset="0" stop-color="gray"/><stop offset="0.239" stop-color="#4b4b4b"/><stop offset="0.31" stop-color="#777"/><stop offset="0.399" stop-color="#a7a7a7"/><stop offset="0.483" stop-color="#cdcdcd"/><stop offset="0.561" stop-color="#e9e9e9"/><stop offset="0.629" stop-color="#f9f9f9"/><stop offset="0.681" stop-color="#fff"/><stop offset="0.786" stop-color="#d1d1d1"/><stop offset="0.93" stop-color="#979797"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h84-j" x1="110" x2="110" xlink:href="#h84-b" y1="99.897" y2="96.179"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h84-k" x1="109.999" x2="109.999" xlink:href="#h84-a" y1="176.287" y2="148.605"/><symbol id="h84-l" viewBox="0 0 7.687 2.688"><path d="M0,2.688H4.444A4.584,4.584,0,0,0,7.687,1.344L0,.252Z" fill="url(#h84-a)"/><path d="M7.687,1.344A4.584,4.584,0,0,0,4.444,0H0V1.344Z" fill="url(#h84-b)"/></symbol></defs><g filter="url(#h84-c)"><path d="M103.2,99.4v59.859M105.922,99.4v59.859M108.641,99.4v59.859M111.359,99.4v59.859M114.077,99.4v59.859M116.8,99.4v59.859" fill="none" stroke="url(#h84-d)" stroke-miterlimit="2.961"/><line fill="none" stroke="url(#h84-e)" stroke-miterlimit="2.961" x1="91.113" x2="128.887" y1="102.5" y2="102.5"/><line fill="none" stroke="url(#h84-f)" stroke-miterlimit="2.961" stroke-width="1.2" x1="91.113" x2="128.887" y1="101.5" y2="101.5"/><use height="2.688" transform="translate(121.771 100.656) scale(1.308 1)" width="7.687" xlink:href="#h84-l"/><use height="2.688" transform="matrix(-1.308, 0, 0, 1, 98.224, 100.656)" width="7.687" xlink:href="#h84-l"/><polygon fill="url(#h84-g)" points="101.651 157.466 102.293 158.466 117.775 158.466 118.417 157.466 101.651 157.466"/><path d="M144.864,150.309c-1.317-18.363-19.966-29.5-19.966-49.457,0-6.039,10.143-2.724,10.143-9.042s-14.85-5.272-14.85,9.042c0,19.8,12.713,35.86,12.713,48.678,0,4.532-2.444,12.182-9.175,12.182-3.709,0-5.346-4.28-5.346-4.28H101.617s-1.637,4.28-5.347,4.28c-6.73,0-9.174-7.65-9.174-12.182,0-12.818,12.713-28.88,12.713-48.678,0-14.314-14.85-15.361-14.85-9.042s10.143,3,10.143,9.042c0,19.959-18.649,31.094-19.966,49.457C73.791,169.068,87.789,181.642,110,181.642S146.209,169.068,144.864,150.309Z" fill="url(#h84-h)"/><path d="M110,175.454c-23.875,0-34.986-11.8-33.866-26.849,1.18-15.856,19.968-27.158,19.968-47.753,0-6.947-10.143-3.787-10.143-9.042,0-1.986,1.972-2.691,3.661-2.691,3.693,0,9.19,3.125,9.19,11.733,0,10.779-3.886,20.557-7.315,29.184-2.777,6.988-5.4,13.587-5.4,19.494,0,5.1,2.762,13.182,10.174,13.182,3.432,0,5.311-2.94,5.988-4.279h15.484c.677,1.339,2.556,4.279,5.987,4.279,7.413,0,10.175-8.085,10.175-13.182,0-5.907-2.622-12.506-5.4-19.494-3.429-8.627-7.315-18.4-7.315-29.184,0-8.608,5.5-11.733,9.19-11.733,1.689,0,3.661.7,3.661,2.691,0,5.29-10.143,2.065-10.143,9.042,0,20.818,18.784,31.846,19.968,47.753C145.257,167.291,129.693,175.454,110,175.454Z" fill="url(#h84-i)"/><path d="M104.563,98.038a1.359,1.359,0,1,1-1.359-1.359A1.358,1.358,0,0,1,104.563,98.038Zm1.359-1.359a1.359,1.359,0,1,0,1.36,1.359A1.36,1.36,0,0,0,105.922,96.679Zm2.719,0A1.359,1.359,0,1,0,110,98.038,1.359,1.359,0,0,0,108.641,96.679Zm2.718,0a1.359,1.359,0,1,0,1.359,1.359A1.359,1.359,0,0,0,111.359,96.679Zm2.718,0a1.359,1.359,0,1,0,1.359,1.359A1.359,1.359,0,0,0,114.077,96.679Zm2.718,0a1.359,1.359,0,1,0,1.359,1.359A1.36,1.36,0,0,0,116.8,96.679Z" fill="none" stroke="url(#h84-j)" stroke-miterlimit="10"/><path d="M143.866,148.6c.393,19.739-16.622,25.879-33.869,25.879-16.265,0-34.272-5.588-33.868-25.879C73.183,170.166,95.061,176.287,110,176.287,125.12,176.287,146.823,170.238,143.866,148.6Z" fill="url(#h84-k)"/></g>'
					)
				)
			);
	}
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import './ICategories.sol';

interface IHardwareSVGs {
    struct HardwareData {
        string title;
        ICategories.HardwareCategories hardwareType;
        string svgString;
    }
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

interface ICategories {
    enum FieldCategories {
        MYTHIC,
        HERALDIC
    }

    enum HardwareCategories {
        STANDARD,
        SPECIAL
    }
}