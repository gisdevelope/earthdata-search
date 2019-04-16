import React, { PureComponent } from 'react'
import PropTypes from 'prop-types'
import classNames from 'classnames'
import moment from 'moment'

import Alert from 'react-bootstrap/Alert'
import Button from 'react-bootstrap/Button'
import Dropdown from 'react-bootstrap/Dropdown'
import Form from 'react-bootstrap/Form'

import Datepicker from './Datepicker'

import './TemporalSelectionDropdown.scss'

/**
 * TODO:
 * - Find a way to better handle invalid dates. Currently, they will be removed from the inputs. This is due to limitations
 *   in the react-datetime package. It does not provide a way to display invalid dates.
 * - Find a way to prevent viewing sets of dates that do not have clickable items in the picker
 */

/**
 * Component representing the temporal selection dropdown
 * @extends Component
 */
export default class TemporalSelectionDropdown extends PureComponent {
  constructor(props) {
    super(props)

    this.state = {
      open: false,
      temporal: {
        endDate: '',
        startDate: ''
      }
    }

    this.onApplyClick = this.onApplyClick.bind(this)
    this.onClearClick = this.onClearClick.bind(this)
    this.onToggleClick = this.onToggleClick.bind(this)
    this.setEndDate = this.setEndDate.bind(this)
    this.setStartDate = this.setStartDate.bind(this)
  }


  componentWillReceiveProps(nextProps) {
    const {
      temporalSearch
    } = this.props

    const [startDate, endDate] = nextProps.temporalSearch.split(',')

    if (temporalSearch !== nextProps.temporalSearch) {
      this.setState({
        temporal: {
          endDate,
          startDate
        }
      })
    }
  }

  /**
   * Opens or closes the dropdown depending on the current state
   */
  onToggleClick() {
    const { open } = this.state

    this.setState({
      open: !open
    })
  }

  /**
   * Sets the current start and end dates values in the Redux store
   */
  onApplyClick() {
    const { onChangeQuery } = this.props

    const { temporal } = this.state
    const { startDate, endDate } = temporal

    onChangeQuery({
      temporal: [
        startDate,
        endDate
      ].join(',')
    })

    this.setState({
      open: false
    })
  }

  /**
   * Clears the current temporal values internally and within the Redux store
   */
  onClearClick() {
    this.setState({
      temporal: {
        startDate: '',
        endDate: ''
      },
      open: false
    })

    const { onChangeQuery } = this.props

    onChangeQuery({ temporal: '' })
  }

  /**
   * Set the startDate prop
   * @param {moment} startDate - The moment object representing the startDate
   */
  setStartDate(startDate) {
    const {
      temporal
    } = this.state

    this.setState({
      temporal: {
        ...temporal,
        startDate: startDate.isValid() ? moment.utc(startDate).toISOString() : startDate._i // eslint-disable-line
      }
    })
  }

  /**
   * Set the endDate prop
   * @param {moment} endDate - The moment object representing the endDate
   */
  setEndDate(endDate) {
    const {
      temporal
    } = this.state

    this.setState({
      temporal: {
        ...temporal,
        endDate: endDate.isValid() ? moment.utc(endDate).toISOString() : endDate._i // eslint-disable-line
      }
    })
  }

  /**
   * Check the start and end dates and return an object containing any applicable errors
   * @param {object} temporal - An object containing temporal values
   */
  checkTemporal(temporal) {
    const start = moment(temporal.startDate)
    const end = moment(temporal.endDate)
    const value = {
      startAfterEnd: false,
      invalidDate: false
    }

    if (temporal && temporal.startDate && temporal.endDate) {
      if (end.isBefore(start)) {
        value.startAfterEnd = true
      }
    }

    if (temporal && temporal.startDate) {
      value.invalidStartDate = !moment.utc(temporal.startDate, 'YYYY-MM-DDTHH:m:s.SSSZ', true).isValid()
    }

    if (temporal && temporal.endDate) {
      value.invalidEndDate = !moment.utc(temporal.endDate, 'YYYY-MM-DDTHH:m:s.SSSZ', true).isValid()
    }

    return value
  }

  render() {
    const {
      open,
      temporal
    } = this.state

    const temporalState = this.checkTemporal(temporal)

    const classes = {
      btnApply: classNames(
        'temporal-selection-dropdown__button',
        'temporal-selection-dropdown__button--apply'
      ),
      btnCancel: classNames(
        'temporal-selection-dropdown__button',
        'temporal-selection-dropdown__button--cancel'
      ),
      inputStart: classNames(
        'temporal-selection-dropdown__input-group',
        'temporal-selection-dropdown__input-group--start'
      ),
      inputEnd: classNames(
        'temporal-selection-dropdown__input-group',
        'temporal-selection-dropdown__input-group--end'
      )
    }

    return (
      <Dropdown show={open} className="temporal-selection-dropdown">
        <Dropdown.Toggle
          variant="inline-block"
          id="dropdown-basic"
          className="search-form__button"
          onClick={this.onToggleClick}
        >
          <i className="fa fa-clock-o" />
        </Dropdown.Toggle>
        <Dropdown.Menu className="temporal-selection-dropdown__menu">
          <div className="temporal-selection-dropdown__inputs">
            <Form.Group controlId="startDate" className={classes.inputStart}>
              <Form.Label className="temporal-selection-dropdown__label">
                Start
              </Form.Label>
              <Datepicker
                onSubmit={value => this.setStartDate(value)}
                type="start"
                value={temporal.startDate}
              />
            </Form.Group>
            <Form.Group controlId="endDate" className={classes.inputEnd}>
              <Form.Label className="temporal-selection-dropdown__label">
                End
              </Form.Label>
              <Datepicker
                onSubmit={value => this.setEndDate(value)}
                type="end"
                value={temporal.endDate}
              />
            </Form.Group>
          </div>
          <Alert show={temporalState.startAfterEnd} variant="danger">
            <strong>Start</strong>
            {' '}
            must be no later than
            {' '}
            <strong>End</strong>
          </Alert>
          <Alert
            variant="danger"
            show={
              temporalState.invalidStartDate || temporalState.invalidStartDate
            }
          >
            Invalid
            {` ${temporalState.invalidStartDate ? 'start' : 'end'} ` }
            date
          </Alert>
          <Form.Group controlId="formBasicChecbox">
            <Form.Check>
              <Form.Check.Input type="checkbox" />
              <Form.Check.Label className="temporal-selection-dropdown__label">
                Recurring?
              </Form.Check.Label>
            </Form.Check>
          </Form.Group>
          <div>
            <Button
              className={classes.btnApply}
              variant="primary"
              onClick={this.onApplyClick}
              disabled={temporalState.startAfterEnd}
            >
              Apply
            </Button>
            <Button
              className={classes.btnCancel}
              variant="link"
              onClick={this.onClearClick}
            >
              Clear
            </Button>
          </div>
        </Dropdown.Menu>
      </Dropdown>
    )
  }
}

TemporalSelectionDropdown.defaultProps = {
  temporalSearch: ''
}

TemporalSelectionDropdown.propTypes = {
  onChangeQuery: PropTypes.func.isRequired,
  temporalSearch: PropTypes.string
}