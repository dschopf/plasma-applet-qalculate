/*
    Copyright 2016 Daniel Schopf <schopfdan@gmail.com>

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) version 3, or any
    later version accepted by the membership of KDE e.V. (or its
    successor approved by the membership of KDE e.V.), which shall
    act as a proxy defined in Section 6 of version 3 of the license.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0

Item {
    id: qwinstance
    property var qwr: null
    property bool initFailed: false

    function getInstance() {
        if (qwr !== null) {
            return qwr
        }
        if (!initFailed) {
            dbgprint('initializing QWrapper ...')
            try {
                qwr = Qt.createQmlObject('import org.kde.private.qalculate 1.0 as QWR; QWR.QWrapper {}', qwinstance, 'QWrapper')
            } catch (e) {
                print('QWrapper failed to initialize' + e)
                initFailed = true
            }
            dbgprint('initializing QWrapper ... done ' + qwr)
        }
        return qwr
    }

    function evaluate(expr) {
        var q = getInstance()
        for (var prop in q) {
          print(prop += " (" + typeof(q[prop]) + ") = " + q[prop]);
        }
        if (q) {
            return q.eval(expr)
        } else {
            dbgprint('QWrapper is not available')
            return "Error"
        }
    }

    function last_result_is_integer() {
        var q = getInstance()
        if (q) {
            return q.last_result_is_integer()
        } else {
            dbgprint('QWrapper is not available')
            return "Error"
        }
    }

    function get_last_result_as(base) {
        var q = getInstance()
        if (q) {
            return q.get_last_result_as(base)
        } else {
            dbgprint('QWrapper is not available')
            return "Error"
        }
    }

    function set_auto_post_conversion(value) {
        var q = getInstance()
        if (q) {
            return q.set_auto_post_conversion(value)
        } else {
            dbgprint('QWrapper is not available')
            return "Error"
        }
    }

    function set_structuring_mode(mode) {
        var q = getInstance()
        if (q) {
            return q.set_structuring_mode(mode)
        } else {
            dbgprint('QWrapper is not available')
            return "Error"
        }
    }

    function set_angle_unit(value) {
        var q = getInstance()
        if (q) {
            return q.set_angle_unit(value)
        } else {
            dbgprint('QWrapper is not available')
            return "Error"
        }
    }

    function set_expression_base(base) {
        var q = getInstance()
        if (q) {
            return q.set_expression_base(base)
        } else {
            dbgprint('QWrapper is not available')
            return "Error"
        }
    }

    function set_result_base(base) {
        var q = getInstance()
        if (q) {
            return q.set_result_base(base)
        } else {
            dbgprint('QWrapper is not available')
            return "Error"
        }
    }

    function set_number_fraction_format(format) {
        var q = getInstance()
        if (q) {
            return q.set_number_fraction_format(format)
        } else {
            dbgprint('QWrapper is not available')
            return "Error"
        }
    }

    function set_numerical_display(value) {
        var q = getInstance()
        if (q) {
            return q.set_numerical_display(value)
        } else {
            dbgprint('QWrapper is not available')
            return "Error"
        }
    }

    function set_indicate_infinite_series(value) {
        var q = getInstance()
        if (q) {
            return q.set_indicate_infinite_series(value)
        } else {
            dbgprint('QWrapper is not available')
            return "Error"
        }
    }

    function set_use_all_prefixes(value) {
        var q = getInstance()
        if (q) {
            return q.set_use_all_prefixes(value)
        } else {
            dbgprint('QWrapper is not available')
            return "Error"
        }
    }

    function set_use_denominator_prefix(value) {
        var q = getInstance()
        if (q) {
            return q.set_use_denominator_prefix(value)
        } else {
            dbgprint('QWrapper is not available')
            return "Error"
        }
    }

    function set_negative_exponents(value) {
        var q = getInstance()
        if (q) {
            return q.set_negative_exponents(value)
        } else {
            dbgprint('QWrapper is not available')
            return "Error"
        }
    }

    function update_exchange_rates() {
        var q = getInstance()
        if (q) {
            return q.update_exchange_rates()
        } else {
            dbgprint('QWrapper is not available')
            return "Error"
        }
    }

    function supports_exchange_rates_time() {
        var q = getInstance()
        if (q) {
            return q.supports_exchange_rates_time()
        } else {
            dbgprint('QWrapper is not available')
            return "Error"
        }
    }

    function get_exchange_rates_time() {
        var q = getInstance()
        if (q) {
            return q.get_exchange_rates_time()
        } else {
            dbgprint('QWrapper is not available')
            return "Error"
        }
    }

    function set_decimal_separator(separator) {
        var q = getInstance()
        if (q) {
            return q.set_decimal_separator(separator)
        } else {
            dbgprint('QWrapper is not available')
            return "Error"
        }
    }

    function set_timeout(timeout) {
        var q = getInstance()
        if (q) {
            return q.set_timeout(timeout)
        } else {
            dbgprint('QWrapper is not available')
            return "Error"
        }
    }
}
